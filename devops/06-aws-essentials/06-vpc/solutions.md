# Solutions - VPC

The AWS console changes its layout from time to time. If a button below has moved,
search for the page by name in the console's search bar: the goal of each step is
what matters, not the exact click path.

## Tier 1
**1.1** VPC → **Your VPCs** → **Create VPC** → **VPC only** → Name tag `amigos-vpc` →
**IPv4 CIDR manual input**, `10.0.0.0/16` → **No IPv6 CIDR block** → Tenancy
**Default** → **Add new tag** `course` / `aws-essentials` → **Create VPC**.

Picked a different CIDR? It can't be changed: **Actions** → **Delete VPC**, and
create it again.

**1.2** VPC → **Subnets** → **Create subnet** → VPC ID `amigos-vpc` → Subnet name
`public-a`, Availability Zone **US East (N. Virginia) / us-east-1a**, IPv4 subnet CIDR
block `10.0.1.0/24` → **Add new subnet** → `public-b`, us-east-1b, `10.0.2.0/24` →
**Add new subnet** → `private-a`, us-east-1a, `10.0.11.0/24` → **Add new subnet** →
`private-b`, us-east-1b, `10.0.12.0/24` → **Create subnet**.

A typo in a name: select the subnet → **Tags** → **Manage tags** → fix **Name**. A
wrong CIDR or zone can't be changed: delete the subnet and create it again.

**1.3** VPC → **Internet gateways** → **Create internet gateway** → Name tag
`amigos-igw` → **Create internet gateway**. The green banner offers **Attach to a
VPC**; or **Actions** → **Attach to VPC** → `amigos-vpc` → **Attach internet gateway**.

**1.4** VPC → **Route tables** → **Create route table** → Name `public-rt`, VPC
`amigos-vpc` → **Create route table**. **Routes** tab → **Edit routes** → **Add
route** → Destination `0.0.0.0/0`, Target **Internet Gateway** → `igw-...`
(amigos-igw) → **Save changes**. **Subnet associations** tab → **Explicit subnet
associations** → **Edit subnet associations** → tick `public-a`, `public-b` → **Save
associations**.

Again for `private-rt`: **Create route table** → `private-rt`, `amigos-vpc` → don't
touch **Routes** → **Subnet associations** → `private-a`, `private-b`.

The VPC also has a third, unnamed route table marked **Main = Yes**. A subnet that is
not associated with any table uses that one. Leave it alone.

**1.5** VPC → **Subnets** → tick `public-a` → **Actions** → **Edit subnet settings** →
**Auto-assign IP settings** → tick **Enable auto-assign public IPv4 address** →
**Save**. Same for `public-b`.

## Tier 2
**2.1** EC2 → **Security Groups** → **Create security group** → name `bastion-sg`,
description `ssh from my ip`, VPC **amigos-vpc** → **Inbound rules** → **Add rule** →
Type **SSH**, Source **My IP** → **Tags** `course` / `aws-essentials` → **Create
security group**.

EC2 → **Launch instances** → Name `amigos-bastion` → **Add additional tags** →
`course` / `aws-essentials` → **Amazon Linux 2023 AMI** → `t3.micro` → Key pair
`amigos-key` → **Network settings** → **Edit** → VPC `amigos-vpc`, Subnet `public-a`,
Auto-assign public IP **Enable** → **Select existing security group** → `bastion-sg`
→ **Launch instance**.

**2.2** **Create security group** → `app-sg`, description `ssh from the bastion`, VPC
**amigos-vpc** → **Add rule** → Type **SSH**, Source **Custom**, click in the box next
to it and type `bastion-sg` → pick `sg-... (bastion-sg)` → **Create security group**.
(Don't see `bastion-sg` in the list? The two groups are in different VPCs - both
must be in `amigos-vpc`.)

**Launch instances** → `amigos-app`, the same as the bastion, except: Subnet
`private-a`, Auto-assign public IP **Disable**, security group `app-sg`.

**2.3** Instances → `amigos-bastion` → **Public IPv4 address**; `amigos-app` →
**Private IPv4 addresses**. Put them in `~/.ssh/config` as in the README, then
`ssh amigos-app`.

- Asked twice to confirm a host key? That is one for the bastion, one for the app -
  type `yes` both times.
- On Windows, if `ProxyJump` fails with *CreateProcessW failed*, write the full path
  of ssh: `ProxyCommand C:\Windows\System32\OpenSSH\ssh.exe -W %h:%p amigos-bastion`
  instead of the `ProxyJump` line.
- `ssh amigos-bastion` times out: your IP changed (new Wi-Fi, VPN) - edit
  `bastion-sg`'s rule back to **My IP**.

**2.4** `curl -m 5 https://checkip.amazonaws.com` → *Connection timed out after 5000
milliseconds*.

**2.5** VPC → **Network ACLs** → the row whose **VPC** is `amigos-vpc` (Default
**Yes**, associated with 4 subnets) → **Inbound rules** → **Edit inbound rules** →
**Add new rule** → Rule number `90`, Type **SSH (22)**, Source `203.0.113.7/32` (*your*
IP, as in `bastion-sg`), Allow/Deny **Deny** → **Save changes**. Try `ssh
amigos-bastion` (it hangs; Ctrl+C), then **Edit inbound rules** → **Remove** rule 90
→ **Save changes**.

## Tier 3
**3.1** VPC → **NAT gateways** → **Create NAT gateway** → Name `amigos-nat` →
Availability mode **Zonal** → Subnet `public-a` → Connectivity type **Public** →
**Allocate Elastic IP** → **Create NAT gateway**. Wait for **Available**.

A NAT gateway in a private subnet is created without complaint, and never works: its
own traffic has no route to the internet gateway. If you made one there, delete it,
release its Elastic IP (EC2 → **Elastic IPs** → **Actions** → **Release Elastic IP
addresses**), and create it in `public-a`.

**3.2** VPC → **Route tables** → `private-rt` → **Routes** → **Edit routes** → **Add
route** → Destination `0.0.0.0/0`, Target **NAT Gateway** → `nat-...` (amigos-nat) →
**Save changes**.

**3.3** `ssh amigos-app`, then the README's commands. The IP `curl` prints is the
NAT gateway's **Primary public IPv4 address** (VPC → NAT gateways → `amigos-nat`).

**3.4** `./course.sh stop 06-vpc`. Deleting a NAT gateway takes about a minute;
`stop` waits for it, then releases its Elastic IP and deletes the VPC.

### Answers
1. Only their route tables. `public-rt` sends `0.0.0.0/0` to the internet gateway,
   `private-rt` does not. Nothing about the subnet itself is "public" - change the
   route and it changes sides.
2. SSH connected to the bastion (it has a public IP and `bastion-sg` lets your IP in),
   and the bastion forwarded a second SSH connection to `amigos-app`'s private IP
   inside the VPC. Both logins used the key on your laptop. A key copied onto the
   bastion would be stolen together with the bastion.
3. A security group as the source means "any server in that group", whatever its IP.
   The bastion's IP changes when it is replaced; the group stays. And nothing else in
   the VPC can SSH to the app, even from the same subnet.
4. The NAT gateway forwards the private servers' traffic to the internet, so it needs
   a route there itself: through the internet gateway, which only a public subnet
   has. A NAT gateway in a private subnet has nowhere to send the traffic.
5. The NAT gateway replaces the private server's address with its own public IP on
   the way out, and translates the reply back. No: the NAT only lets replies to
   connections started from inside back in. Nothing on the internet can start one.
6. A security group is stateful and guards one server (its network card): allow a
   request in, and the reply goes out automatically. A network ACL is stateless and
   guards a whole subnet: it checks each packet in each direction against numbered
   rules, lowest first, and the first match wins - so a Deny at 90 beats an Allow at
   100.
7. An availability zone is one or more data centres; a zone can fail. With subnets in
   two zones you can run copies of a server in both. AWS requires it for a load
   balancer (two zones at least) and for an RDS database's subnet group.
