# 03 - IAM

> Maps to **AWS Essentials - Section 3: IAM**
> (users, groups, managed and custom policies, least privilege, the policy simulator, password policy)

**IAM** (Identity and Access Management) decides who can do what in your account.
Right now only one identity exists - root - and it can do everything. In this
section you stop using root for good: you create an admin user for yourself, and a
developer who can only *read* files - and you prove what she can and can't do. Every
team on AWS runs on exactly these building blocks. IAM is free.

## The building blocks

- **User** - one person (or app) with their own sign-in. `amigos-admin` is you from now on.
- **Group** - a set of users that share permissions. Give permissions to groups,
  never to users one by one: when someone joins the team, you just add them to a group.
- **Policy** - a JSON document that **allows** (or denies) **actions** (`s3:GetObject`)
  on **resources** (a bucket, or `*` for all). AWS ships hundreds of *managed*
  policies like `AdministratorAccess`; you can also write your own.
- **Role** - permissions with no password attached, that something *assumes* for a
  while: an EC2 server, a Lambda function, another account. Roles are how servers
  get access to AWS without you ever pasting keys onto them. You create one for a
  server in section 04 (S3), once there is a bucket for it to read.
- **Least privilege** - give every identity only the actions it needs, nothing more.
  If dev-alice's password leaks, the damage is "someone read some files", not
  "someone deleted the company".

Everything is **denied by default**. A user with no policies can sign in and do
nothing at all.

## How to use this set

From the `devops/06-aws-essentials/` folder:

```bash
./course.sh verify 03-iam    # check your work
./course.sh reset  03-iam    # delete dev-alice, developers and the policy, start fresh
                             # (amigos-admin and Admins are never deleted - you sign in with them)

# Windows (PowerShell or Command Prompt): course.cmd instead of ./course.sh
```

Do this section signed in to the console as **root** until task 1.4, then as
**amigos-admin**. If section 01's **IAM access to Billing** drill is not done yet,
do it now as root - otherwise amigos-admin cannot see the bill.

---

## Tier 1 - Stop using root *(hint: IAM → User groups, then Users)*

**1.1 (graded)** Create a **user group** named `Admins` and attach the AWS managed
policy **AdministratorAccess** to it.

**1.2 (graded)** Create a **user** named `amigos-admin` with **console access**
(choose "I want to create an IAM user" and set a password) and add it to the `Admins`
group. On the review page, add the tag `course` = `aws-essentials` (task 3.2 checks it).

**1.3 (graded)** Give `amigos-admin` its own **MFA** device: IAM → Users →
`amigos-admin` → **Security credentials** → **Assign MFA device**. An admin without
MFA is one leaked password away from a root-level disaster.

**1.4 (graded)** Become `amigos-admin`. Sign out of the console, then sign in with
your account alias link from section 01 -
`https://<your-alias>.signin.aws.amazon.com/console` - as `amigos-admin`. Then sign
the checker in as amigos-admin too:

```bash
./course.sh logout
./course.sh login        # in the browser, sign in as amigos-admin, not root
./course.sh whoami       # Signed in as: amigos-admin
```

> From here on, root stays locked away. You only need it for a handful of account
> settings, like closing the account or changing the support plan.

---

## Tier 2 - Least privilege *(hint: IAM → Policies → Create policy → JSON)*

**2.1 (graded)** Create a user group `developers` and a user `dev-alice` in it.
dev-alice does not need console access for this exercise. Tag her `course` =
`aws-essentials`.

**2.2 (graded)** Write your own policy. IAM → **Policies** → **Create policy** →
**JSON**, and paste:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadS3",
      "Effect": "Allow",
      "Action": ["s3:ListAllMyBuckets", "s3:ListBucket", "s3:GetObject"],
      "Resource": "*"
    }
  ]
}
```

Name it `S3ReadOnlyCourse`, tag it `course` = `aws-essentials`, and attach it to
the **`developers` group** (not to dev-alice herself).

> Read it out loud: *allow listing buckets, listing what is in a bucket, and
> downloading objects - on every bucket*. No `Put`, no `Delete`. In section 04 you
> narrow `"Resource"` down to one bucket.

**2.3 (graded)** Prove it. Open the **IAM Policy Simulator**
([policysim.aws.amazon.com](https://policysim.aws.amazon.com)), pick **Users →
dev-alice**, choose the **S3** service and simulate `GetObject`, `PutObject` and
`DeleteBucket`. Reading must be **allowed**, writing and deleting **denied**. The
checker runs the same simulation.

---

## Tier 3 - Account hygiene *(hint: IAM → Account settings, then Credential report)*

**3.1 (graded)** Set an account **password policy** (IAM → **Account settings** →
**Password policy** → **Edit** → **Custom**) with a minimum length of at least **12**
characters.

**3.2 (graded)** Everything you created that can carry tags does: `amigos-admin`,
`dev-alice` and `S3ReadOnlyCourse` all have the tag `course` =
`aws-essentials`. (Groups can't be tagged.) Forgot one? Open it → **Tags** tab →
**Add new tag**.

**3.3 (drill)** Download the **credential report** (IAM → **Credential report** →
**Download**). It lists every user, whether they have MFA, and when their password
and access keys were last used. Find the `<root_account>` row: `access_key_1_active`
should be `false`. If root has access keys, delete them (account menu → Security
credentials) - `./course.sh login` means you never need them.

All green = you never use root again, and people get only the access they need.
That is IAM done the way real teams do it. Servers get theirs through a role, in
section 04.

---

## Self-check questions

1. Why attach policies to **groups** instead of directly to users?
2. A brand-new IAM user has no policies. What can they do?
3. What is the difference between a **user** and a **role**?
4. dev-alice is in `developers`, and `developers` has `S3ReadOnlyCourse`. You remove
   her from the group. What can she do now?
5. dev-alice's password leaks. With `S3ReadOnlyCourse`, what is the worst that can
   happen? What if she had been in `Admins`?
