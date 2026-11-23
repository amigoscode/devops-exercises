# Solutions - S3

The AWS console changes its layout from time to time. If a button below has moved,
search for the page by name in the console's search bar: the goal of each step is
what matters, not the exact click path. Replace `<account-id>` with your 12-digit
account ID everywhere.

## Tier 1
**1.1** S3 → **Create bucket** → check the region in the top right is **US East (N.
Virginia)** → **General purpose** → name `amigos-files-<account-id>` → leave **ACLs
disabled** and **Block all public access** ticked → **Tags** → **Add tag** `course` /
`aws-essentials` → **Create bucket**.

**1.2** Nothing to change if you kept the defaults. Open the bucket → **Permissions**:
**Block public access (bucket settings)** shows **On**, and **Bucket policy** is empty.

**1.3** Open the bucket → **Create folder** → `notes` → **Create folder**. Open
`notes/` → **Upload** → **Add files** → `04-s3/files/hello.txt` → **Upload**.

**1.4** Click `hello.txt` → copy **Object URL** → private window → `AccessDenied`.
Back in the console: **Object actions** → **Share with a presigned URL** → 5 minutes →
**Create presigned URL** → open it. After 5 minutes the same link says `Request has expired`.

## Tier 2
**2.1** Bucket → **Properties** → **Bucket Versioning** → **Edit** → **Enable** →
**Save changes**.

**2.2** Edit `files/hello.txt` (e.g. `version 1` → `version 2`), save, and upload it
to `notes/` again. Turn on **Show versions**: two rows for `hello.txt`, the newest
with the latest version ID.

**2.3** **Show versions** off → tick `hello.txt` → **Delete** → type `delete`.
**Show versions** on → tick the row whose type is **Delete marker** → **Delete** →
type `permanently delete`. `hello.txt` is back with the version you uploaded last.

**2.4** Bucket → **Management** → **Create lifecycle rule** → name
`cleanup-old-versions` → **Apply to all objects in the bucket** → tick the
acknowledgement → under **Lifecycle rule actions** tick:
- **Move noncurrent versions of objects between storage classes** → **Standard-IA**,
  **Days after objects become noncurrent** `30`
- **Permanently delete noncurrent versions of objects** → `90` days
- **Delete expired object delete markers or incomplete multipart uploads** → tick
  **Delete incomplete multipart uploads** → `7` days

→ **Create rule**. (Standard-IA needs at least 30 days - the console refuses less.)

## Tier 3
**3.1** **Create bucket** → `amigos-site-<account-id>` → us-east-1 → tag `course` /
`aws-essentials` → **Create bucket**. Open it → **Upload** → `website/index.html`
and `website/error.html` (at the top, not in a folder) → **Upload**. **Properties** →
**Static website hosting** → **Edit** → **Enable** → **Host a static website** →
index document `index.html`, error document `error.html` → **Save changes**.

**3.2** **Permissions** → **Block public access (bucket settings)** → **Edit** →
untick **Block all public access** → **Save changes** → type `confirm`. Then
**Bucket policy** → **Edit** → paste the policy from the README with your account ID
→ **Save changes**. The bucket now shows **Publicly accessible** in red - on purpose.

**3.3** **Properties** → scroll to **Static website hosting** → click the **Bucket
website endpoint**. Your page. Add `/nope`: your error page, sent with status `404`.
Without an error document, S3 shows its own bare error page instead.

**3.4** IAM → **Policies** → search `S3ReadOnlyCourse` → open it → **Edit** → **JSON**
→ paste the narrowed policy from the README → **Next** → **Save changes**. IAM keeps
the old wide version as version 1; **Policy versions** shows both.

To see it yourself: the [policy simulator](https://policysim.aws.amazon.com) → **Mode:
New policy** → paste the policy → S3 → `GetObject` with resource
`arn:aws:s3:::amigos-files-<account-id>/notes/hello.txt` is allowed, the same action
on `arn:aws:s3:::amigos-site-<account-id>/index.html` is denied.

## Tier 4
**4.1** IAM → **Roles** → **Create role** → **AWS service** → use case **EC2** → Next →
tick `S3ReadOnlyCourse` → Next → name `ec2-s3-reader` → **Add tag** `course` /
`aws-essentials` → **Create role**. Its **Trust relationships** tab shows:
```json
{ "Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com" }, "Action": "sts:AssumeRole" }
```
Creating it this way (AWS service → EC2) also creates the **instance profile** of the
same name - that is what the launch wizard lists.

**4.2** EC2 → **Instances** → **Launch instances**:
- **Name and tags**: `amigos-reader` → **Add additional tags** → `course` /
  `aws-essentials`, Resource types **Instances** and **Volumes**
- **Amazon Linux 2023 AMI**, `t3.micro`, key pair `amigos-key`
- **Network settings** → **Edit**: default VPC, **Auto-assign public IP** **Enable**,
  **Create security group** → Security group name `reader-sg` → the SSH rule's
  **Source type** → **My IP**
- **Advanced details** → **IAM instance profile** → `ec2-s3-reader`

→ **Launch instance**. Forgot the role? **Actions** → **Security** → **Modify IAM role**
→ `ec2-s3-reader` → **Update IAM role** - unlike user data, a role can be attached
any time.

**4.3** Copy the instance's **Public IPv4 address** into a `Host amigos-reader` block
in `~/.ssh/config`, then `ssh amigos-reader`.

**4.4** Run the commands from the README on the server. `aws sts get-caller-identity`
shows `arn:aws:sts::<account-id>:assumed-role/ec2-s3-reader/i-...`. If the files
bucket is denied too, the narrowed policy has a wrong ARN (3.4). If the site bucket
is *allowed*, the policy is still the wide one from section 03.

**4.5** `exit`, `./course.sh stop 04-s3`. It terminates `amigos-reader`, deletes
`reader-sg`, the role and both buckets.

### Answers
1. Bucket names are global - one namespace for every AWS account in the world (they
   become part of a web address). IAM names only have to be unique inside your own
   account.
2. S3 refuses to save it: `BlockPublicPolicy` rejects any new policy that grants
   public access. (If a public policy was already there, `RestrictPublicBuckets`
   makes it stop working.) That is why you switch it off for the site bucket only.
3. Every old version of the file, plus a **delete marker** on top that makes it look
   deleted. Delete the delete marker and the newest real version is current again.
   Only deleting a specific *version* removes data for good.
4. `amigos-files-123` is the **bucket** itself - `s3:ListBucket` needs it.
   `amigos-files-123/*` is **every object inside** - `s3:GetObject`, `PutObject` and
   `DeleteObject` need that one. Use the wrong one and the action is simply denied.
5. The **bucket policy** is attached to the bucket and names who (a `Principal`) may
   do what to it. The **identity policy** (`S3ReadOnlyCourse`) is attached to a user,
   group or role and names what *they* may do, to which resources. AWS checks both.
6. From the **instance metadata service** (`169.254.169.254`). The instance profile
   tells EC2 which role the server has; the metadata service hands out short-lived
   credentials for it and rotates them before they expire. The AWS CLI and SDKs look
   there on their own when no keys are configured.
7. No. The credentials stay the same, but every request is checked against the
   policy as it is *now*, so the change applies within seconds.
