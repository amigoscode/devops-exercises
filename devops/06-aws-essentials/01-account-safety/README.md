# 01 - Account Safety

> Maps to **AWS Essentials - Section 1: Your AWS Account**
> (what AWS is, regions and availability zones, the root user, MFA, budgets and the free plan)

Before you build anything on AWS, you lock the account down. An AWS account is tied
to your card, and the root user can do *anything* - including run up a bill. Every
real team starts the same way: secure the root user, put alarms on the bill, then
learn where things live in the console. That is this whole section, and it costs
nothing.

## What is AWS?

**Amazon Web Services** rents you computers, storage, databases and networks by the
hour (or by the second). Instead of buying a server, you click a button and one is
running a minute later - and when you delete it, you stop paying.

Four ideas you will meet in every section of this course:

- **Regions** - AWS runs data centres all over the world, grouped into regions like
  *US East (N. Virginia)* (`us-east-1`) or *Europe (Ireland)* (`eu-west-1`). Most
  things you create live in one region, and the console only shows the region picked
  in the top-right corner. **This course uses `us-east-1` for everything.**
- **Availability Zones** - each region is several separate data centres (AZs) a few
  miles apart, like `us-east-1a` and `us-east-1b`. Spreading your app across two of
  them means one data centre can fail and your app keeps running.
- **Shared responsibility** - AWS secures the buildings, hardware and its own
  software. *You* secure what you put on it: who can sign in, what is public, which
  ports are open. Most AWS horror stories are on the customer's side of that line.
- **Pay for what you use** - you are billed for what is running, so the habit that
  saves you money is simple: **build it, check it, delete it**.

## How to use this set

Everything runs through one launcher script, from the `devops/06-aws-essentials/` folder:

```bash
./course.sh login                     # sign the checker in to your AWS account (task 1.2)
./course.sh verify 01-account-safety  # check your work
./course.sh whoami                    # which account is the checker signed in to?

# Windows (PowerShell or Command Prompt): course.cmd instead of ./course.sh
```

You build everything by **clicking in the AWS console**. The checker only *reads*
your account (with the official AWS CLI, running in Docker) - it never changes
anything.

---

## Tier 1 - Create and secure your account *(hint: account menu → Security credentials)*

**1.1 (drill)** Create your AWS account at
[aws.amazon.com/free](https://aws.amazon.com/free) and pick the **Free plan** when
asked. You need an email address, a phone number and a card - on the Free plan AWS
will not charge the card; it uses free credits instead. The email address and
password you sign up with are your **root user**.

> New accounts can take a few minutes (rarely a few hours) to be fully activated.
> If a service says your account is "being verified", wait for the welcome email.

**1.2 (graded)** Sign the checker in to your account. In this folder run:

```bash
./course.sh login        # Windows: course.cmd login
```

It prints a link. Open it, sign in as your root user, and AWS shows you a code -
paste it back into the terminal. The checker now has a short-lived session for your
account. It only ever reads from it, no access keys are created, and
`./course.sh logout` removes the session again.

> Signing in as root is fine *here* because nothing is stored but a short-lived session.
> From section 03 (IAM) on you sign the checker in as your own admin user instead.

**1.3 (graded)** Turn on **MFA** for the root user. Open the account menu (your
account name, top right) → **Security credentials** → **Assign MFA device**, and use
an authenticator app on your phone or a passkey. From now on, signing in as root
needs your password *and* your phone.

> Never create **access keys** for the root user. Leaked root keys are how accounts
> get emptied.

---

## Tier 2 - Guard the bill *(hint: Billing and Cost Management → Budgets)*

**2.1 (graded)** Create a monthly **cost budget** named `amigoscode-budget` with a
budget amount of **$5**. Use **Customize (advanced)** → **Cost budget**, so you can
set the alert yourself in 2.2.

**2.2 (graded)** Give `amigoscode-budget` an **email alert** on **actual** spend at
**80%** of the budget ($4). If you leave something running by mistake, this is the
email that tells you.

**2.3 (graded)** Add a second budget from the **Zero spend budget** template, named
`amigoscode-zero-spend`. It emails you the moment your account spends *anything* -
on the Free plan, that should never happen.

**2.4 (drill)** Find out how many **free credits** you have and when your Free plan
ends: Billing and Cost Management → **Credits** (or the Free Tier page). The checker
prints them too.

---

## Tier 3 - Find your way around *(hint: IAM → Dashboard → AWS Account)*

**3.1 (drill)** Pick **US East (N. Virginia)** in the region menu (top right). Then
search for **IAM**, **EC2**, **S3**, **VPC** and **Billing and Cost Management** in the
search bar and star them, so they sit in your favourites bar.

**3.2 (graded)** Create an **account alias** like `amigos-<yourname>` (IAM →
Dashboard → **AWS Account** → **Account Alias** → **Create**). It gives your account a
sign-in link people can remember: `https://amigos-<yourname>.signin.aws.amazon.com/console`.
Aliases are unique across all of AWS, so add something personal.

**3.3 (drill)** Let IAM users see the bill: account menu → **Account** → **IAM user
and role access to Billing information** → **Edit** → **Activate IAM Access**. Without
this, the admin user you create in section 03 cannot open Billing or Budgets, even
with full admin rights.

All green = your account is locked down, the bill has alarms on it, and you know
your way around the console. Everything you build from here starts on safe ground.

---

## Self-check questions

1. What is the difference between a **region** and an **availability zone**?
2. Why is the root user so dangerous, and why should it never have access keys?
3. What does MFA protect you from, even if your password leaks?
4. Your `amigoscode-budget` alert fires at $4. Name two places you would look to find
   what is costing money.
5. Under the shared responsibility model, whose job is it to stop an S3 bucket from
   being public: AWS's or yours?
