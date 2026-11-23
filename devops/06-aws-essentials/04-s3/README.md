# 04 - S3

> Maps to **AWS Essentials - Section 4: S3**
> (buckets, objects, Block Public Access, presigned URLs, versioning, lifecycle rules, static websites, bucket policies, IAM roles for EC2)

**S3** (Simple Storage Service) stores files - AWS calls them **objects** - in
**buckets**. It is the hard drive of the internet: app uploads, backups, logs, build
artifacts, whole websites. You pay for what you store and download, and at the size
of this section that is well under one cent.

In this section you build two buckets: a **private** one for files that only your
own users and servers may read, and a **public** one that serves a website to anyone.
Then you give a server an **IAM role** that reads the private bucket - and nothing
else - without a single access key on the box.
Knowing exactly which of the two a bucket is - and keeping it that way - is the most
important S3 skill there is. Most S3 data leaks in the news are a bucket that was
public by accident.

## The building blocks

- **Bucket** - a container for objects. It lives in one region, and its name is
  **unique across all of AWS**: nobody else, in any account, can have the same one.
  That is why your bucket names below end in your account ID.
- **Object** - a file plus its metadata, up to 5 TB. Its name is its **key**, like
  `notes/hello.txt`. S3 has no real folders: `notes/` is just the start of the key,
  which the console shows as a folder.
- **Block Public Access** - four switches, on by default, that stop a bucket from ever
  being made public. Leave them on unless the bucket really is meant for everyone.
- **Bucket policy** - a JSON policy attached to the *bucket*, saying who may do what
  with it. In section 03 you wrote policies for *people* (identity
  policies); this is the other side: a policy on the *resource*.
- **Versioning** - keeps every version of every object. Overwrite or delete a file
  and the old one is still there. Your undo button.
- **Storage classes** - the same object can be stored cheaper if you read it less:
  **Standard** (default), **Standard-IA** (infrequent access), **Glacier** (archive).
  **Lifecycle rules** move objects between classes, and delete them, on a schedule.
- **Encryption** - every new object is encrypted at rest automatically (SSE-S3). You
  do not need to switch anything on.
- **Role for EC2** - an IAM role a server *assumes*. Programs on the server get the
  role's short-lived credentials from the instance metadata service
  (`169.254.169.254`) on their own - no keys to copy, nothing to leak. The role is
  attached through an **instance profile**, which the console makes for you.

## Your bucket names

Bucket names must be unique worldwide, so yours end in your 12-digit **account ID**
(the account menu in the top right of the console, or `./course.sh whoami`):

| Bucket | Name | Who can read it |
|--------|------|-----------------|
| files  | `amigos-files-<account-id>` | only your users and roles |
| site   | `amigos-site-<account-id>`  | anyone on the internet |

For account `123456789012` that is `amigos-files-123456789012`. The checker prints
your two names at the top of every check.

## How to use this set

From the `devops/06-aws-essentials/` folder:

```bash
./course.sh start  04-s3     # creates the policy from section 03 if missing
./course.sh verify 04-s3     # check your work
./course.sh stop   04-s3     # delete both buckets, the server and the role

# Windows (PowerShell or Command Prompt): course.cmd instead of ./course.sh
```

The files you upload are in the repo, in this section's folder:

- `devops/06-aws-essentials/04-s3/files/hello.txt`
- `devops/06-aws-essentials/04-s3/website/index.html` and `website/error.html`

In the console's **Upload** dialog, **Add files** and pick them from that folder. In
**Codespaces** they are not on your laptop: right-click the file in the Explorer →
**Download** first, then upload the downloaded copy.

Sign in to the console as **amigos-admin** (section 03), region **us-east-1**.

> **Cost:** S3 is well under one cent - it charges per GB stored and per request, and
> this section stores a few kilobytes. The server in Tier 4 is billed by the hour,
> about **1.5 cents an hour**: do Tier 4 in one sitting. `stop` deletes everything.

---

## Tier 1 - A private bucket *(hint: S3 → Create bucket)*

**1.1 (graded)** Create a bucket named `amigos-files-<account-id>` in **US East (N.
Virginia) us-east-1**. Keep every default - **Block all public access** stays ticked,
**ACLs disabled** stays selected. Under **Tags** add `course` = `aws-essentials`.

> Created it in the wrong region? Buckets can't move. Delete it and create it again
> in us-east-1.

**1.2 (graded)** Check the lock. Open the bucket → **Permissions** → **Block public
access (bucket settings)**: all four settings are **On**, and there is no bucket
policy. This is the state every bucket should be in unless it is a website.

**1.3 (graded)** In the bucket, **Create folder** `notes`, open it and **Upload**
`files/hello.txt` from this section's folder. Its key is now `notes/hello.txt`.

**1.4 (drill)** Try to read it as a stranger. Click `hello.txt` → copy its **Object
URL** → open it in a private browser window: `AccessDenied`. Private means private.
Now share it on purpose: **Object actions** → **Share with a presigned URL** → 5
minutes → open that link: it works, for anyone who has it, until it expires. Wait 5
minutes and try again.

---

## Tier 2 - Versioning and lifecycle *(hint: bucket → Properties, then Management)*

**2.1 (graded)** Turn on **Bucket Versioning** (**Properties** → **Bucket
Versioning** → **Edit** → **Enable**).

**2.2 (graded)** Change `files/hello.txt` on your computer (any edit - change
`version 1` to `version 2`) and upload it to `notes/` again. In the bucket, flip
the **Show versions** switch: `hello.txt` now has two versions, and the old one is
still there.

**2.3 (drill)** Delete `notes/hello.txt` (with **Show versions** off). Turn **Show
versions** on: the file is not gone - a **delete marker** sits on top of it. Select
the delete marker and delete *that*: the file is back. With versioning, a delete is
just another version.

**2.4 (graded)** Old versions cost money forever unless something cleans them up.
**Management** → **Create lifecycle rule**, name `cleanup-old-versions`, **Apply to
all objects in the bucket** (tick the acknowledgement), and choose these actions:

- **Move noncurrent versions of objects between storage classes**: **Standard-IA**
  after **30** days
- **Permanently delete noncurrent versions of objects**: after **90** days
- **Delete expired object delete markers or incomplete multipart uploads**: tick
  **Delete incomplete multipart uploads**, after **7** days

> The current version of every file stays in Standard. Only versions you replaced
> or deleted move to cheaper storage after 30 days and disappear after 90.

---

## Tier 3 - A public website, on purpose *(hint: bucket → Properties → Static website hosting)*

**3.1 (graded)** Create a second bucket `amigos-site-<account-id>` (us-east-1, tag
`course` = `aws-essentials`). Upload `website/index.html` and `website/error.html`
to the top of the bucket. Then **Properties** → **Static website hosting** → **Edit**
→ **Enable**, index document `index.html`, error document `error.html`.

**3.2 (graded)** Open it to the world - only this bucket, and only for reading.
**Permissions** → **Block public access** → **Edit** → untick **Block all public
access** → confirm. Then **Bucket policy** → **Edit** and paste (with your account ID):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForWebsite",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::amigos-site-<account-id>/*"
    }
  ]
}
```

> `"Principal": "*"` means *anyone* - the most dangerous word in AWS. It is fine
> here only because the action is `s3:GetObject` (read) and the resource is this one
> bucket's objects. Never `s3:*`, never on your files bucket.
>
> Can't save the policy because *your account* blocks public access? Then S3 →
> **Block Public Access settings for this account** is on. Turn off only **Block
> public access to buckets and objects granted through new public bucket or access
> point policies** and **...any public bucket or access point policies**, finish the
> section, and turn them back on after `stop`.

**3.3 (graded)** Visit it. **Properties** → **Static website hosting** shows the
**Bucket website endpoint**,
`http://amigos-site-<account-id>.s3-website-us-east-1.amazonaws.com`. Open it: your
page. Add `/nope` to the address: your error page. The checker visits both.

> S3 website endpoints are plain HTTP. Real sites put **CloudFront** in front for
> HTTPS and a custom domain - and then the bucket can be private again.

**3.4 (graded)** Remember `S3ReadOnlyCourse` from section 03? It lets anyone with it
read **every** bucket - including any you create later. Narrow it to the files
bucket. IAM → **Policies** → `S3ReadOnlyCourse` → **Edit** → **JSON**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SeeBucketNames",
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*"
    },
    {
      "Sid": "ListTheFilesBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::amigos-files-<account-id>"
    },
    {
      "Sid": "ReadTheFiles",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::amigos-files-<account-id>/*"
    }
  ]
}
```

> Two ARNs, on purpose: `arn:aws:s3:::bucket` is the **bucket** (listing it),
> `arn:aws:s3:::bucket/*` is **every object in it** (reading them). Mixing them up is
> the most common S3 policy bug - the policy saves fine and then nothing works.

The checker asks IAM what something with only this policy could do: read the files
bucket - it must - and read the site bucket or write anywhere - it must not. In Tier
4 a real server gets exactly this policy.

---

## Tier 4 - A server that reads S3 with a role *(hint: IAM → Roles, then EC2 → Launch instances)*

You need your key pair `amigos-key` and the `Host amigos-*` block in `~/.ssh/config`
from section 02 (tasks 1.2 and 2.1). Skipped section 02? Do those two tasks first.

**4.1 (graded)** Create a **role** for a server. IAM → **Roles** → **Create role** →
trusted entity **AWS service**, use case **EC2** → permission `S3ReadOnlyCourse` →
name `ec2-s3-reader` → tag `course` = `aws-essentials` → **Create role**.

> Open the role's **Trust relationships** tab. That JSON says *who* may use the role
> (`ec2.amazonaws.com`); the permissions tab says *what* they can then do. Every role
> has both halves.

**4.2 (graded)** ⚠️ Launch a server with that role. EC2 → **Launch instances**:

- **Name** `amigos-reader` → **Add additional tags** → `course` = `aws-essentials`
- **AMI**: **Amazon Linux 2023** (it comes with the AWS CLI), **type** `t3.micro`
- **Key pair**: `amigos-key`
- **Network settings** → **Edit**: **Auto-assign public IP: Enable**, **Create
  security group**, name `reader-sg`, one rule: **SSH** from **My IP** (no HTTP -
  this server serves nothing)
- **Advanced details** → **IAM instance profile** → `ec2-s3-reader`

No user data this time. **Launch instance**.

> About **1.5 cents an hour** while it runs (server plus public IP). `stop`
> terminates it.

**4.3 (graded)** SSH in. Add the server to `~/.ssh/config`, under the course block:

```
Host amigos-reader
    HostName <public-ip>
```

```bash
ssh amigos-reader
```

**4.4 (graded)** Now be the server. On `amigos-reader`:

```bash
aws sts get-caller-identity       # assumed-role/ec2-s3-reader/i-...: the role
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

aws s3 ls "s3://amigos-files-$ACCOUNT/notes/"            # hello.txt
aws s3 cp "s3://amigos-files-$ACCOUNT/notes/hello.txt" - # prints the file

aws s3 ls "s3://amigos-site-$ACCOUNT"                    # AccessDenied
echo hack | aws s3 cp - "s3://amigos-files-$ACCOUNT/x"   # AccessDenied
```

Nobody typed, pasted or stored a key on this server. The AWS CLI found the role's
credentials in the metadata service by itself, and they expire within hours. And
the role can do exactly what `S3ReadOnlyCourse` says: read one bucket, nothing more.
The checker logs in and runs the same reads.

> AccessDenied on the files bucket too? 3.4 isn't right yet - fix the policy, and the
> server gets the change within seconds, no restart needed.

**4.5 (drill)** `exit`, then `./course.sh stop 04-s3`, and look at EC2 → **Instances**:
`amigos-reader` is **Terminated**. You can remove the `Host amigos-reader` block from
your config.

All green = you can tell a private bucket from a public one, undo any mistake with
versioning, keep storage costs from creeping up, and give a server access to exactly
one bucket - with a role, not a key.

When you are done: `./course.sh stop 04-s3` terminates the server and deletes the
role, both buckets and everything in them.

---

## Self-check questions

1. Why does your bucket name need your account ID in it, when your IAM user names don't?
2. Block Public Access is on and someone adds a bucket policy with `"Principal": "*"`.
   What happens?
3. Versioning is on and you delete a file. What is actually stored now, and how do
   you get the file back?
4. What is the difference between `arn:aws:s3:::amigos-files-123` and
   `arn:aws:s3:::amigos-files-123/*`? Which actions need which?
5. A bucket policy and an identity policy both mention the same bucket. Which one is
   attached to what?
6. How does `aws s3 cp` on amigos-reader get credentials, if nobody gave it any?
7. You narrow `S3ReadOnlyCourse` while amigos-reader is running. Do you need to
   restart the server for the change to apply?
