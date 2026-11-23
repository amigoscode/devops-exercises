# 02 - EC2

> Maps to **AWS Essentials - Section 2: EC2**
> (instances, AMIs, instance types, security groups, key pairs and SSH, user data, the metadata service, Docker on EC2, Elastic IPs)

**EC2** (Elastic Compute Cloud) gives you servers - AWS calls them **instances** -
in about a minute, by the hour. It is the oldest and most used AWS service: almost
everything else (load balancers, databases, containers) runs on EC2 underneath.

In this section you launch a web server and work on it the way a DevOps engineer
does. A **security group** lets in web traffic from everyone and SSH only from you,
a **key pair** and your `~/.ssh/config` get you onto the server with one short
command, and **user data** prepares the website on first boot. Over SSH you
install **Docker** and run **nginx in a container** - the same `docker run` you
know from the Docker course, now on a server on the internet. Then you give it a
fixed address with an **Elastic IP**.

## The building blocks

- **Instance** - a virtual server. You pay per second while it is **running**.
- **AMI** (Amazon Machine Image) - the disk image an instance boots from: the
  operating system plus anything pre-installed. You use **Amazon Linux 2023**.
- **Instance type** - the size: CPU and memory. `t3.micro` is 2 vCPUs and 1 GiB,
  enough for a small web server, and free-tier eligible.
- **EBS volume** - the instance's disk. It lives on even when the instance is stopped
  (and is billed while it does). Section 05 is all about it.
- **Security group** - a firewall around the instance. It only has **allow** rules,
  and it is **stateful**: if a request is allowed in, the reply is allowed out.
- **Key pair** - a public key that AWS puts on the server, and a private key (the
  `.pem` file) that only you have. SSH proves you hold the private key; there is no
  password to guess. You make **one** key pair, `amigos-key`, and use it for every
  server in this course.
- **User data** - a script the instance runs once, as root, at its first boot.
- **Instance metadata service** - an address every instance can reach,
  `169.254.169.254`, that tells the server about itself: its ID, type, zone, IP.
  Your user data reads it to fill in the home page.
- **Public IP vs Elastic IP** - an instance's public IP changes every time it is
  stopped and started. An **Elastic IP** is yours until you release it.

## How to use this set

From the `devops/06-aws-essentials/` folder:

```bash
./course.sh start  02-ec2    # makes sure you have a default VPC (see below)
./course.sh verify 02-ec2    # check your work
./course.sh stop   02-ec2    # terminate the server, release the Elastic IP, delete the rest
                             # (your key pair amigos-key is kept - every later section uses it)

# Windows (PowerShell or Command Prompt): course.cmd instead of ./course.sh
```

`start` checks that your account has a **default VPC** - the network new servers go
in - and creates one if it was deleted. (Section 06 builds a network of your own.)

Sign in to the console as **root** for this section, region **us-east-1**. Section
03 (IAM) creates the admin user you use from then on.

> ⚠️ **This section costs money by the hour.** A `t3.micro` server is about
> **$0.01/hour**, its public IP **$0.005/hour**, and the Elastic IP in 3.1 another
> **$0.005/hour** - roughly **2 cents an hour** for everything, about **$15 a month**
> if you forget it. Free plan credits cover it, but **do the whole section in one
> sitting, then run `./course.sh stop 02-ec2`**. A *stopped* instance still pays
> for its disk and IPs - only terminating stops the bill. The checker lists anything
> still running at the end of every check.

---

## Tier 1 - Launch a server *(hint: EC2 → Key pairs, Security Groups, then Launch instance)*

**1.1 (graded)** Create a security group named `web-sg` (EC2 → **Security Groups** →
**Create security group**) in the **default VPC**, description `web and ssh`. Two
inbound rules:

- **HTTP**, port **80**, source **Anywhere-IPv4** (`0.0.0.0/0`) - the website is for everyone
- **SSH**, port **22**, source **your IP only**: pick **My IP**, or **Custom** with
  the address `curl -s https://checkip.amazonaws.com` prints in the terminal you will
  run `ssh` from, followed by `/32`

Leave the outbound rule as it is (all traffic). Tag `course` = `aws-essentials`.

> **Never** open SSH to `0.0.0.0/0`. A server with port 22 open to the internet gets
> login attempts from bots within minutes. Only your IP may even try.
>
> In **Codespaces**, your terminal is not on your laptop: use the address `curl`
> prints *in the Codespace*, not the console's "My IP". Home IP changed, or a new
> Codespace? Edit the rule to your new address.

**1.2 (graded)** Create your course key pair. EC2 → **Key pairs** → **Create key
pair** → name `amigos-key`, type **ED25519**, format **.pem** → **Create key pair**.
Your browser downloads `amigos-key.pem` - **the only copy there will ever be**. Move
it into your `.ssh` folder and make it readable only by you (SSH refuses keys that
others can read):

```bash
# macOS / Linux / WSL / Git Bash / Codespaces
mkdir -p ~/.ssh && mv ~/Downloads/amigos-key.pem ~/.ssh/
chmod 400 ~/.ssh/amigos-key.pem
```
```powershell
# Windows PowerShell
mkdir -Force $HOME\.ssh; Move-Item $HOME\Downloads\amigos-key.pem $HOME\.ssh\
icacls $HOME\.ssh\amigos-key.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

> **Codespaces**: drag `amigos-key.pem` from your laptop into the Codespace's file
> explorer first, then `mv` it from there. Never commit it - a private key in a git
> repo is a leaked key.

**1.3 (graded)** Launch the server: EC2 → **Instances** → **Launch instances**.

- **Name** `amigos-web` → **Add additional tags** → `course` = `aws-essentials`
  (resource types: Instances and Volumes)
- **AMI**: **Amazon Linux 2023** (the default, *not* the "minimal" one)
- **Instance type**: `t3.micro`
- **Key pair**: `amigos-key`
- **Network settings** → **Edit**: the default VPC, **Auto-assign public IP:
  Enable**, **Select existing security group** → `web-sg`
- **Advanced details** (click to expand it) → **User data** - the big text box at
  the very **bottom** of Advanced details. Paste in the whole script below.

The script is in the repo at `devops/06-aws-essentials/02-ec2/user-data.sh`, and
below. Copy all of it, from `#!/bin/bash` to the last line. Easiest is straight from
the file: open it in your editor and select all, or on a Mac run
`pbcopy < devops/06-aws-essentials/02-ec2/user-data.sh` from the repo root.

```bash
#!/bin/bash
# User data for amigos-web: paste all of it into EC2 → Launch instances →
# Advanced details → User data. It runs once, as root, at the first boot.
# It only prepares the website: it writes the home page to /srv/www.
# Installing Docker and running nginx is your job (Tier 2).
mkdir -p /srv/www

# Ask the instance metadata service (IMDSv2) who and where this server is.
IMDS=http://169.254.169.254/latest
TOKEN=$(curl -s -X PUT "$IMDS/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
meta() {
  curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$IMDS/meta-data/$1"
}

cat > /srv/www/index.html <<PAGE
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>amigos-web</title>
<style>
  body { margin: 0; min-height: 100vh; display: grid;
         place-items: center; font-family: system-ui, sans-serif;
         background: #0f172a; color: #e2e8f0; }
  main { max-width: 36rem; padding: 2rem; }
  h1   { font-size: 2.2rem; margin: 0 0 .5rem; }
  span, a { color: #a78bfa; }
  code { background: #1e293b; padding: .1rem .35rem; }
</style>
</head>
<body>
<main>
  <h1>Hello from <span>amigos-web</span> 👋</h1>
  <p>nginx in a Docker container, on an EC2 server you launched.</p>
  <p>Instance <code>$(meta instance-id)</code>,
     type <code>$(meta instance-type)</code>,
     in <code>$(meta placement/availability-zone)</code>.</p>
  <p>This page was written by user data, at the server's first boot.</p>
</main>
</body>
</html>
PAGE

chmod -R a+rX /srv/www
```

Then **Launch instance**. It takes about a minute to be **Running**. The user data
puts your home page in `/srv/www` - nothing serves it yet. That is Tier 2.

---

## Tier 2 - SSH in, run nginx in Docker *(hint: ~/.ssh/config)*

**2.1 (graded)** Set up SSH once, for the whole course. Open `~/.ssh/config` in any
editor (create it if it doesn't exist - Windows: `$HOME\.ssh\config`, no file
extension) and add:

```
# ---- AWS Essentials: every server in the course ----------------------------
Host amigos-*
    User ec2-user
    IdentityFile ~/.ssh/amigos-key.pem
    IdentitiesOnly yes
    UserKnownHostsFile ~/.ssh/known_hosts_amigos
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60

# One block per server. HostName is the instance's Public IPv4 address.
Host amigos-web
    HostName <public-ip>
```

The `Host amigos-*` block is the course's settings, for every server you will ever
name `amigos-something`: log in as `ec2-user` (Amazon Linux's user) with your course
key, and remember the servers' host keys in their own file. Each server then needs
only its own two lines. Every later section adds a block like `amigos-web` - and
that is all it takes to reach it. Now:

```bash
ssh amigos-web
```

The first time, SSH shows the server's fingerprint and remembers it. You are in:

```bash
whoami                         # ec2-user
ls -l /srv/www                 # what user data prepared: index.html
cat /etc/os-release | head -2  # Amazon Linux 2023
```

> `ssh amigos-web` instead of `ssh -i ~/.ssh/amigos-key.pem ec2-user@54.83.103.140`.
> A newer SSH on your side may print *"WARNING: connection is not using a
> post-quantum key exchange algorithm"*: your SSH is newer than the server's, the
> connection is still encrypted, carry on.
> Connection timed out? Port 22 isn't open to your current IP (1.1). "Permission
> denied (publickey)"? The server was launched with another key, or the `.pem` path
> in your config is wrong. "UNPROTECTED PRIVATE KEY FILE"? Do the `chmod` / `icacls`
> from 1.2.

**2.2 (graded)** On the server, install Docker and start it - now, and at every boot:

```bash
sudo dnf install -y docker
sudo systemctl enable --now docker
sudo docker version            # Client and Server: the Docker daemon is running
```

> Same Docker as in the Docker course, different machine. `sudo`, because ec2-user
> is not in the `docker` group.

**2.3 (graded)** Run nginx in a container named `web`:

```bash
sudo docker run -d --name web --restart unless-stopped \
  -p 80:80 \
  -v /srv/www:/usr/share/nginx/html:ro \
  nginx:alpine

sudo docker ps                 # web   nginx:alpine   Up ...   0.0.0.0:80->80/tcp
curl -s localhost | head -5    # nginx answers from inside the server (give it a second)
```

Every flag matters: `-p 80:80` publishes the container's port 80 on the server's
port 80 (the one `web-sg` lets in), `-v ... :ro` serves `/srv/www` read-only instead
of nginx's default page, and `--restart unless-stopped` brings the container back
after a reboot. Now open `http://<public-ip>` in your browser (plain `http://`). Your
page shows the instance ID and availability zone, read from the metadata service.

> Page doesn't load? `sudo docker ps` must show `0.0.0.0:80->80/tcp`, and `web-sg`
> must allow HTTP from `0.0.0.0/0`. Shows "Welcome to nginx!"? The `-v` mount is
> missing: `sudo docker rm -f web` and run it again.

**2.4 (drill)** `exit` the SSH session. **Instance state** → **Stop instance**, wait
for **Stopped**, then **Start instance**. Three things to see:

- The **public IP changed**: the old address in your browser no longer works.
- `ssh amigos-web` no longer works either - your config still has the old
  `HostName`. Put the new IP in, and it works again.
- The **container came back on its own**: `ssh amigos-web sudo docker ps`. That is
  `systemctl enable` (Docker starts at boot) plus `--restart unless-stopped`
  (Docker starts `web`).

Editing your config every time the server restarts is no way to live. Tier 3 fixes it.

---

## Tier 3 - A fixed address *(hint: EC2 → Elastic IPs)*

**3.1 (graded)** ⚠️ Give it an address that stays put. EC2 → **Elastic IPs** →
**Allocate Elastic IP address** → tag `course` = `aws-essentials` → **Allocate**.
Then **Actions** → **Associate Elastic IP address** → instance `amigos-web` →
**Associate**. Open `http://<elastic-ip>`: your page. Put the Elastic IP in your
config as `amigos-web`'s `HostName` - for good this time - and `ssh amigos-web`.

> An Elastic IP is billed **$0.005/hour from the moment you allocate it until you
> release it** - attached or not. An Elastic IP left behind after its server is gone
> is the most common surprise on a first AWS bill. `stop` releases it.

**3.2 (drill)** Stop and start the instance again. The address stays the same, so
`ssh amigos-web` just works - and the container is back too.

**3.3 (drill)** Clean up and look: `./course.sh stop 02-ec2`, then the **EC2
dashboard** shows 0 running instances and 0 Elastic IPs (in us-east-1 - check the
region). Make this a habit after every section. Keep `amigos-key.pem` and your
`~/.ssh/config` - the next sections add their servers to it. (Remove the
`Host amigos-web` block if you like; a new `amigos-web` gets a new address.)

All green = you can launch a server that only you can log in to, reach any course
server with `ssh amigos-<name>`, run a container on it that survives reboots, and
keep its address.

---

## Self-check questions

1. You stop the instance for a week. What are you still paying for?
2. Your security group allows port 80 in. Why don't you need an outbound rule for
   nginx's replies?
3. User data didn't run because you forgot to paste it. Why doesn't adding it later
   and rebooting fix it?
4. The home page shows the instance ID, but nobody typed it in. Where did the user
   data script get it from?
5. Why is SSH open to `0.0.0.0/0` dangerous even though you need the private key
   to log in?
6. You rebooted the server and the site is down. Name the two settings that make the
   container come back on its own.
7. You relaunched `amigos-web` and moved the Elastic IP to the new server. `ssh
   amigos-web` now shouts "REMOTE HOST IDENTIFICATION HAS CHANGED". Why, and what do
   you do?
