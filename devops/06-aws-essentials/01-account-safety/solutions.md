# Solutions - Account Safety

The AWS console changes its layout from time to time. If a button below has moved,
search for the page by name in the console's search bar: the goal of each step is
what matters, not the exact click path.

## Tier 1
**1.1** Go to [aws.amazon.com/free](https://aws.amazon.com/free) → **Create a free
account**. Enter your email and an account name, confirm the email code, set the root
password, add your contact details, card and phone verification, then choose the
**Free plan**. Wait for the "Welcome to Amazon Web Services" email.

**1.2** From `devops/06-aws-essentials/`:
```bash
./course.sh login
# open the printed link → sign in as root → copy the code AWS shows → paste it here
./course.sh whoami     # Account: 123456789012 / Signed in as: the root user
```

**1.3** Account name (top right) → **Security credentials** → **Multi-factor
authentication (MFA)** → **Assign MFA device** → name it (e.g. `root-phone`) →
**Authenticator app** → scan the QR code with Google Authenticator, Authy or 1Password
→ type two codes in a row → **Add MFA**. (A **passkey or security key** works too.)

## Tier 2
**2.1** Search **Budgets** → **Create budget** → **Customize (advanced)** → **Cost
budget** → Next. Name `amigoscode-budget`, period **Monthly**, renewal **Recurring**,
budgeting method **Fixed**, amount **5.00** → Next.

**2.2** Still in the wizard: **Add an alert threshold** → threshold **80**, **% of
budgeted amount**, trigger **Actual** → email recipients: your email → Next →
**Create budget**.

**2.3** **Create budget** → **Use a template (simplified)** → **Zero spend budget** →
name `amigoscode-zero-spend` → your email → **Create budget**.

**2.4** Billing and Cost Management → **Credits** shows the credits left and their
expiry. `./course.sh verify 01-account-safety` prints the same numbers.

## Tier 3
**3.1** Region menu (top right) → **US East (N. Virginia) us-east-1**. Type each
service name in the search bar and click the ☆ next to it.

**3.2** Search **IAM** → **Dashboard** → right-hand panel **AWS Account** → **Account
Alias** → **Create** → `amigos-<yourname>` → **Save changes**. Your sign-in link is
shown right there.

**3.3** Account name (top right) → **Account** → scroll to **IAM user and role access
to Billing information** → **Edit** → tick **Activate IAM Access** → **Update**. Only
the root user can change this.

### Answers
1. A **region** is a geographic area (`us-east-1`); an **availability zone** is one of
   the separate data centres inside it (`us-east-1a`). Spread across AZs for resilience.
2. Root can do everything, including close the account and change billing, and IAM
   policies cannot limit it. Keys for root never expire on their own, so a leaked key
   is total, lasting access.
3. A stolen password alone is no longer enough to sign in: the attacker would also
   need your phone or passkey.
4. **Cost Explorer** (cost grouped by service and region) and **Bills** (charges per
   service). Then look in each region - most things only show in their own region.
5. Yours. AWS gives you Block Public Access and bucket policies; whether you leave a
   bucket public is on your side of the shared responsibility model.
