# AWS Essentials - Hands-On Exercises

Hands-on, auto-graded AWS exercises for the Amigoscode **AWS Essentials** course. You
build real infrastructure in your own AWS account - users, buckets, servers,
networks, load balancers and databases - by clicking through the AWS console, and a
script checks your account with instant ✅ / ❌ feedback.

By the end you will do what a DevOps engineer does on AWS every day: secure an
account, give people and servers only the access they need, run a web app on EC2
behind a load balancer inside your own VPC, connect it to a managed database, and
get alerted when something goes wrong.

> **Easiest way in:** run `./academy.sh` (Windows: `academy.cmd`) from the repo root.
> It opens this course in a terminal app - lessons, instant grading and progress
> tracking. The commands below still work if you prefer them.

## How this course is different

In the other courses the grader looks inside a container on your machine. Here it
looks at **your real AWS account**: you build everything in the AWS console, then
the checker reads what you built - which users, buckets and instances exist, how
they are configured - and grades it.

- **Your own AWS account.** Section 01 walks you through creating one on the AWS
  **Free plan**, which uses free credits instead of charging your card.
- **Docker is still the only thing you install.** The checker is the official AWS
  CLI, run in a container. It signs in with `aws login` (your normal console sign-in
  in the browser) and gets short-lived credentials - you never create access keys.
- **One region.** Everything lives in **US East (N. Virginia) `us-east-1`**. If you
  can't find something you built, check the region menu in the top right.

## How to use this set

**macOS, Linux, WSL, Git Bash, Codespaces**

```bash
# from the devops/06-aws-essentials/ folder
./course.sh login                      # once per session: sign the checker in
./course.sh start  01-account-safety   # set up what the section needs
#   ...build it in the AWS console, then:
./course.sh verify 01-account-safety   # check your work
./course.sh reset  01-account-safety   # delete what the section created, start fresh
./course.sh stop   01-account-safety   # delete everything the section created
./course.sh whoami                     # which account is the checker signed in to?
./course.sh logout                     # forget the sign-in
```

**Windows (PowerShell or Command Prompt)**: the same commands with `course.cmd`
instead of `./course.sh`. Windows has no `bash`, so `course.cmd` runs the same
script inside a tiny throwaway container wired to your Docker.

## Build it, check it, delete it

AWS bills for what is running, so every section ends by deleting what you built. A
few things are billed **by the hour** even when idle (a NAT gateway, an Elastic IP, a
load balancer, a database). Those tasks carry a ⚠️ box: build them, check them and
delete them in the **same sitting**. The `$5` budget alert from section 01 is your
safety net.

Each section's `start` creates what earlier sections would have built (an IAM role,
a VPC, security groups...), so you can do any section on its own. `reset` and `stop`
delete those again.

## One SSH setup for every server

From section 02 on you log in to servers over SSH. You set it up **once**, in section
02, and keep it for the whole course:

- one key pair, `amigos-key`, saved as `~/.ssh/amigos-key.pem` - `stop` never deletes it
- one block in `~/.ssh/config` for every server named `amigos-*`:

```
Host amigos-*
    User ec2-user
    IdentityFile ~/.ssh/amigos-key.pem
    IdentitiesOnly yes
    UserKnownHostsFile ~/.ssh/known_hosts_amigos
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
```

Each section then adds one short block per server it launches (`Host amigos-web`,
`HostName <its-ip>`), and `ssh amigos-web` just works. Every security group allows
SSH from **your IP only**, never from the whole internet.

## Sections

| # | Section | What you build |
|---|---------|----------------|
| 01 | [Account Safety](01-account-safety/) | root MFA, budget alerts, account alias, the console tour |
| 02 | [EC2](02-ec2/) | a server with nginx in Docker, a key pair and your SSH config, security groups, user data, an Elastic IP |
| 03 | [IAM](03-iam/) | an admin user, groups, a least-privilege policy, the policy simulator |
| 04 | [S3](04-s3/) | buckets, versioning, Block Public Access, a static website, lifecycle rules, a server that reads S3 with a role |
| 05 | [EBS and AMIs](05-ebs-amis/) | a data disk mounted with fstab, a snapshot you restore, a disk grown live, your own AMI |
| 06 | [VPC](06-vpc/) | your own network: public and private subnets in two zones, a bastion, a NAT gateway |
| 07 | Load Balancing and Auto Scaling *(coming soon)* | an Application Load Balancer and a self-healing group |
| 08 | RDS *(coming soon)* | PostgreSQL in private subnets, its password in Secrets Manager, a failover |
| 09 | Monitoring *(coming soon)* | CloudWatch alarms, email alerts, dashboards, logs |
| 10 | Capstone *(coming soon)* | the microservices app from the Docker course, deployed on AWS |
