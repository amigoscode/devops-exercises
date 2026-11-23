# Solutions - IAM

The AWS console changes its layout from time to time. If a button below has moved,
search for the page by name in the console's search bar: the goal of each step is
what matters, not the exact click path.

## Tier 1
**1.1** IAM → **User groups** → **Create group** → name `Admins` → in **Attach
permissions policies** tick **AdministratorAccess** → **Create user group**.

**1.2** IAM → **Users** → **Create user** → name `amigos-admin` → tick **Provide
user access to the AWS Management Console** → **I want to create an IAM user** →
**Custom password** → Next → **Add user to group** → tick `Admins` → Next → under
**Tags** add `course` = `aws-essentials` → **Create user**. Save the sign-in link it shows.

**1.3** Users → `amigos-admin` → **Security credentials** → **Assign MFA device** →
name it (e.g. `amigos-admin-phone`) → **Authenticator app** → scan the QR code →
type two codes in a row → **Add MFA**.

**1.4** Account menu → **Sign out**. Open `https://<your-alias>.signin.aws.amazon.com/console`,
sign in as `amigos-admin` with your password and MFA code. Then:
```bash
./course.sh logout
./course.sh login       # sign in as amigos-admin in the browser, paste the code
./course.sh whoami      # Signed in as: amigos-admin
```

## Tier 2
**2.1** **User groups** → **Create group** → `developers` (no policies yet) → Create.
**Users** → **Create user** → `dev-alice` (leave console access off) → Next → **Add
user to group** → `developers` → Next → tag `course` = `aws-essentials` → Create user.

**2.2** **Policies** → **Create policy** → **JSON** tab → paste the policy from the
README → Next → name `S3ReadOnlyCourse` → add tag `course` = `aws-essentials` →
**Create policy**. Then **User groups** → `developers` → **Permissions** → **Add
permissions** → **Attach policies** → tick `S3ReadOnlyCourse` → **Attach policies**.

**2.3** [policysim.aws.amazon.com](https://policysim.aws.amazon.com) → left panel
**Users** → `dev-alice` → **Select service**: S3 → **Select actions**: `GetObject`,
`PutObject`, `DeleteBucket` → **Run Simulation**. GetObject: **allowed**. PutObject
and DeleteBucket: **denied** (implicitly - nothing allows them).

## Tier 3
**3.1** **Account settings** → **Password policy** → **Edit** → **Custom** →
minimum length `12` (tick the character types you want) → **Save changes**.

**3.2** For each of `amigos-admin`, `dev-alice` (Users) and `S3ReadOnlyCourse`
(Policies): open it → **Tags** → **Add new tag** → `course` /
`aws-essentials` → Save.

**3.3** **Credential report** → **Download credentials report**. Open the CSV: one
row per user plus `<root_account>`. If root's `access_key_1_active` is `true`: account
menu (as root) → **Security credentials** → **Access keys** → **Actions → Deactivate**,
then **Delete**.

### Answers
1. Permissions follow the job, not the person: a new developer joins `developers`
   and has the right access instantly; someone leaves and you remove them from one
   place. Per-user policies drift and get forgotten.
2. Nothing. IAM denies everything by default; they can sign in (if they have a
   password) but every action is refused until a policy allows it.
3. A **user** is a long-lived identity for one person or app, with a password and/or
   keys. A **role** has no credentials of its own: someone or something trusted
   *assumes* it and gets temporary credentials that expire on their own.
4. Nothing. Her permissions came only from the group; without it she has no policy,
   and IAM denies everything by default. That is why access goes on groups.
5. With `S3ReadOnlyCourse`: someone can list buckets and download objects - a data
   leak, but nothing deleted or changed. In `Admins`: they could delete everything,
   create users for themselves and run up any bill. That gap is least privilege.
