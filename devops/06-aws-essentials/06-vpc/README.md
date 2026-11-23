# 06 - VPC

> Maps to **AWS Essentials - Section 6: VPC**
> (VPCs and CIDR blocks, subnets and availability zones, internet gateways, route tables, public and private subnets, bastion hosts, SSH ProxyJump, NAT gateways, security groups vs network ACLs)

Every server so far went into the **default VPC**, a network AWS made for you where
every subnet is public: anything you launch gets a public IP and can be reached from
the internet, if its security group lets it. That is fine for a web server, and wrong
for a database or a backend that nobody outside should ever touch.

In this section you build your own network from nothing: a VPC, public and private
subnets in two availability zones, and the routes that decide which is which. You
put a **bastion** in the public side and a server with no public IP in the private
side, and reach it over SSH through the bastion. Then you give the private side a way
out to the internet - a **NAT gateway** - without letting anyone in.

## The building blocks

- **VPC** (Virtual Private Cloud) - your own private network in one region. You pick
  its address range as a **CIDR block**: `10.0.0.0/16` is the 65,536 addresses from
  `10.0.0.0` to `10.0.255.255`.
- **Subnet** - a slice of the VPC's range in **one availability zone**, like
  `10.0.1.0/24` (256 addresses, 251 usable - AWS keeps 5). Servers live in subnets.
- **Internet gateway** - the VPC's door to the internet. One per VPC, free.
- **Route table** - the signposts for a subnet: "traffic for `10.0.0.0/16` stays
  here (`local`), traffic for anywhere else (`0.0.0.0/0`) goes to ...". Every subnet
  uses exactly one route table; one table can serve many subnets.
- **Public subnet** - a subnet whose route table sends `0.0.0.0/0` to the internet
  gateway. That route, nothing else, is what makes it public.
- **Private subnet** - a subnet with no route to the internet gateway. Its servers
  can't be reached from the internet, and can't reach it either.
- **NAT gateway** - sits in a public subnet and lets private servers start
  connections **out** to the internet (to install packages, call an API), while
  nothing on the internet can start a connection **in**.
- **Bastion host** (jump host) - a small server in a public subnet that you SSH
  through to reach private servers.
- **Security group vs network ACL** - a security group guards one server and is
  **stateful** (a reply to an allowed request is always let back). A network ACL
  guards a whole subnet, is **stateless**, and checks numbered rules in order.

## How to use this set

From the `devops/06-aws-essentials/` folder:

```bash
./course.sh start  06-vpc   # checks you have amigos-key - you build the rest
./course.sh verify 06-vpc   # check your work
./course.sh stop   06-vpc   # delete amigos-vpc and everything inside it,
                            # the NAT gateway and its Elastic IP (amigos-key is kept)

# Windows (PowerShell or Command Prompt): course.cmd instead of ./course.sh
```

You need your key pair `amigos-key` and the `Host amigos-*` block in `~/.ssh/config`
from section 02 (tasks 1.2 and 2.1). Skipped section 02? Do those two tasks first.

Sign in to the console as **amigos-admin**, region **us-east-1**. Most of this
section is in the **VPC** console: search for *VPC* in the top bar.

> ⚠️ **Tier 3 costs money by the hour.** A NAT gateway is **$0.045 an hour** plus
> $0.005 for its Elastic IP - about **$36 a month** if you forget it - and it bills
> even when nothing uses it. With the two servers, Tier 3 is about **7 cents an
> hour**. Tiers 1 and 2 cost only the servers. **Do Tier 3 in one sitting, then run
> `./course.sh stop 06-vpc`.**

---

## Tier 1 - Your own network *(hint: VPC → Your VPCs, Subnets, Internet gateways, Route tables)*

Tier 1 is free: VPCs, subnets, route tables and internet gateways cost nothing.

**1.1 (graded)** Create the VPC. VPC → **Your VPCs** → **Create VPC**:

- **Resources to create**: **VPC only** - you build the rest yourself, piece by piece
  (**VPC and more** would make it all for you, and you would learn nothing)
- **Name tag** `amigos-vpc`, **IPv4 CIDR** `10.0.0.0/16`, no IPv6
- **Tags**: add `course` = `aws-essentials`

**1.2 (graded)** Create four subnets. VPC → **Subnets** → **Create subnet** → VPC
`amigos-vpc`, then one subnet after another (**Add new subnet** for the next):

| Subnet name | Availability Zone | IPv4 subnet CIDR block |
|-------------|-------------------|------------------------|
| `public-a`  | `us-east-1a`      | `10.0.1.0/24`          |
| `public-b`  | `us-east-1b`      | `10.0.2.0/24`          |
| `private-a` | `us-east-1a`      | `10.0.11.0/24`         |
| `private-b` | `us-east-1b`      | `10.0.12.0/24`         |

Two zones, so that when one zone has a bad day, the other keeps working. Load
balancers (section 07) and databases (section 08) insist on two. Right now the four
are identical: none of them can reach the internet. The route tables make the
difference.

**1.3 (graded)** Give the VPC a door. VPC → **Internet gateways** → **Create internet
gateway** → name `amigos-igw` → **Create**. It is **Detached**: **Actions** → **Attach
to VPC** → `amigos-vpc`.

**1.4 (graded)** Make the signposts. VPC → **Route tables** → **Create route table**:

- `public-rt`, VPC `amigos-vpc` → **Create**. **Routes** → **Edit routes** → **Add
  route**: Destination `0.0.0.0/0`, Target **Internet Gateway** → `amigos-igw` →
  **Save**. **Subnet associations** → **Edit subnet associations** → tick `public-a`
  and `public-b` → **Save**.
- `private-rt`, VPC `amigos-vpc`. Leave its routes alone - only `local`. **Subnet
  associations** → `private-a` and `private-b`.

Look at both: they differ by one line, `0.0.0.0/0 → igw-...`. That line is the whole
difference between a public and a private subnet.

**1.5 (graded)** Servers in a public subnet need a public IP. VPC → **Subnets** →
`public-a` → **Actions** → **Edit subnet settings** → tick **Enable auto-assign public
IPv4 address** → **Save**. The same for `public-b`. Leave it off for the private ones.

---

## Tier 2 - A bastion and a private server *(hint: EC2 → Security Groups, then Launch instances)*

**2.1 (graded)** The bastion. First its firewall: EC2 → **Security Groups** →
**Create security group** → name `bastion-sg`, description `ssh from my ip`, **VPC**
`amigos-vpc` (it defaults to the default VPC - change it) → **Inbound rules**: SSH,
Source **My IP** → tag `course` = `aws-essentials` → **Create**.

Then EC2 → **Launch instances**: name `amigos-bastion`, tag `course` =
`aws-essentials`, **Amazon Linux 2023**, `t3.micro`, key pair `amigos-key`. Under
**Network settings** → **Edit**:

- **VPC** `amigos-vpc`, **Subnet** `public-a`, **Auto-assign public IP** **Enable**
- **Select existing security group** → `bastion-sg`

**2.2 (graded)** The private server. Its firewall lets SSH in only from servers in
`bastion-sg` - not from an IP address: **Create security group** → `app-sg`,
description `ssh from the bastion`, VPC `amigos-vpc` → **Inbound rules**: SSH, Source
**Custom**, then type `bastion-sg` in the box and pick the group → **Create**.

Launch `amigos-app` the same way as the bastion, but in **Subnet** `private-a`, with
**Auto-assign public IP** **Disable** and security group `app-sg`. When it is
running, its **Details** show a **Private IPv4 address** like `10.0.11.25` - and no
public one.

**2.3 (graded)** SSH in through the bastion. Add both servers to `~/.ssh/config`:

```
Host amigos-bastion
    HostName <bastion-public-ip>

Host amigos-app
    HostName <app-private-ip>
    ProxyJump amigos-bastion
```

```bash
ssh amigos-bastion 'hostname -I'   # 10.0.1.x - a public-a address
ssh amigos-app                     # through the bastion, in one step
hostname -I                        # 10.0.11.x - you are on the private server
```

**ProxyJump** opens an SSH connection to the bastion, and through it a second one to
`amigos-app`. Both log in with `amigos-key` **from your laptop** - the key never
leaves it. Never copy `amigos-key.pem` onto a bastion: whoever breaks into the
bastion would get the key to every server.

**2.4 (drill)** No way out. Still on `amigos-app`:

```bash
curl -m 5 https://checkip.amazonaws.com   # Connection timed out
```

`private-rt` has no route to anywhere outside the VPC, so the server can't install
packages or call any API on the internet. Tier 3 fixes that.

**2.5 (drill)** Block yourself with a network ACL. VPC → **Network ACLs** → the one
with **VPC** `amigos-vpc` (made with the VPC; it covers all four subnets) →
**Inbound rules** → **Edit inbound rules** → **Add new rule**: Rule number `90`, Type
**SSH**, Source *your IP*`/32` (it is in `bastion-sg`'s inbound rule), **Deny** →
**Save**. Now `ssh amigos-bastion` hangs, although `bastion-sg` still allows you:
the ACL checks rules from the lowest number up, and rule 90 comes before the rule
100 that allows everything. **Delete rule 90** again, and SSH works.

---

## Tier 3 - A way out: the NAT gateway *(hint: VPC → NAT gateways, then Route tables)*

> ⚠️ **Billed by the hour from here on.** Do 3.1 to 3.4 in one go, then `stop`.

**3.1 (graded)** VPC → **NAT gateways** → **Create NAT gateway**:

- **Name** `amigos-nat`
- **Availability mode**: **Zonal** (if the console asks), **Subnet** `public-a` - a
  NAT gateway reaches the internet through the internet gateway, so it must sit in a
  **public** subnet
- **Connectivity type** **Public**, then **Allocate Elastic IP**

→ **Create NAT gateway**. It goes from **Pending** to **Available** in a minute or
two. Note its **Primary public IPv4 address**.

**3.2 (graded)** Point the private side at it. VPC → **Route tables** → `private-rt`
→ **Routes** → **Edit routes** → **Add route**: Destination `0.0.0.0/0`, Target **NAT
Gateway** → `amigos-nat` → **Save**.

**3.3 (graded)** On `amigos-app` (`ssh amigos-app`):

```bash
curl https://checkip.amazonaws.com    # the NAT gateway's public IP
sudo dnf install -y htop              # packages install now
```

The internet sees the NAT gateway's IP, not the server's - `amigos-app` still has no
public IP, and nobody out there can open a connection to it.

**3.4 (drill)** Clean up and look: `./course.sh stop 06-vpc`, then VPC → **NAT
gateways** (**Deleted**), EC2 → **Elastic IPs** (empty) and VPC → **Your VPCs** (only
the default VPC is left). Remove the `amigos-bastion` and `amigos-app` blocks from
your config if you like.

All green = you can build a VPC from scratch, keep servers off the internet in
private subnets, reach them through a bastion, and let them out through a NAT
gateway.

---

## Self-check questions

1. `public-a` and `private-a` are subnets of the same VPC, in the same zone. What
   makes one public and the other private?
2. `amigos-app` has no public IP. How did your SSH reach it - and why did you not copy
   `amigos-key.pem` onto the bastion?
3. Why does `app-sg` allow SSH from the security group `bastion-sg`, not from the
   bastion's IP address?
4. Why must the NAT gateway be in a public subnet, not a private one?
5. `curl` on `amigos-app` printed the NAT gateway's IP. Why? Can someone on the
   internet now open a connection to `amigos-app`?
6. In 2.5 your SSH was blocked although `bastion-sg` allowed it. Which one is
   stateful, a security group or a network ACL, and what does each one guard?
7. Why did you create subnets in two availability zones?
