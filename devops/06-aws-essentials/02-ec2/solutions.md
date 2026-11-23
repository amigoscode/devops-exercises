# Solutions - EC2

The AWS console changes its layout from time to time. If a button below has moved,
search for the page by name in the console's search bar: the goal of each step is
what matters, not the exact click path.

## Tier 1
**1.1** EC2 → **Network & Security** → **Security Groups** → **Create security group**
→ name `web-sg`, description `web and ssh`, VPC: the default one → **Inbound rules**:
- **Add rule** → Type **HTTP**, Source **Anywhere-IPv4**
- **Add rule** → Type **SSH**, Source **My IP** (or **Custom** → the output of
  `curl -s https://checkip.amazonaws.com` in your terminal, plus `/32`)

Leave **Outbound rules** as they are → **Tags** → `course` / `aws-essentials` →
**Create security group**. Later, when your IP changes: **Edit inbound rules** → the
SSH rule → Source **My IP** → **Save rules**.

**1.2** EC2 → **Network & Security** → **Key pairs** → **Create key pair** → name
`amigos-key`, Key pair type **ED25519**, Private key file format **.pem** → **Create
key pair**. Then move it and lock it down:
```bash
mkdir -p ~/.ssh && mv ~/Downloads/amigos-key.pem ~/.ssh/ && chmod 400 ~/.ssh/amigos-key.pem
ls -l ~/.ssh/amigos-key.pem       # -r-------- : only you can read it
```
Windows PowerShell:
```powershell
mkdir -Force $HOME\.ssh; Move-Item $HOME\Downloads\amigos-key.pem $HOME\.ssh\
icacls $HOME\.ssh\amigos-key.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"
```
Lost the `.pem`? AWS doesn't keep a copy. Delete the key pair, create it again, and
launch new servers with it.

**1.3** EC2 → **Instances** → **Launch instances**:
- **Name and tags**: `amigos-web` → **Add additional tags** → Key `course`, Value
  `aws-essentials`, Resource types: **Instances** and **Volumes**
- **Application and OS Images**: **Amazon Linux** → **Amazon Linux 2023 AMI** (Free
  tier eligible), 64-bit (x86)
- **Instance type**: `t3.micro`
- **Key pair (login)**: `amigos-key`
- **Network settings** → **Edit**: VPC: the default one, Subnet: **No preference**,
  **Auto-assign public IP**: **Enable**, **Firewall**: **Select existing security
  group** → `web-sg`
- **Configure storage**: leave the default (8 GiB gp3)
- **Advanced details**: **Metadata version** → **V2 only (token required)** (the
  default); **User data** → paste all of `user-data.sh`

→ **Launch instance** → **View all instances**.

## Tier 2
**2.1** Click `amigos-web` → copy **Public IPv4 address**. Add the course block and the
`amigos-web` block from the README to `~/.ssh/config` (macOS/Linux: `nano
~/.ssh/config`; Windows: `notepad $HOME\.ssh\config` - save it without a `.txt`
extension), with that IP as `HostName`. Then:
```bash
ssh amigos-web
# Warning: Permanently added '...' (ED25519) to the list of known hosts.
# (accept-new says yes for you the first time, and refuses if the key ever changes)
```
To see what SSH makes of your config: `ssh -G amigos-web | grep -E '^(user|hostname|identityfile) '`.

The long way, without a config, is `ssh -i ~/.ssh/amigos-key.pem ec2-user@<public-ip>`.

**2.2** On the server (after `ssh amigos-web`):
```bash
sudo dnf install -y docker
sudo systemctl enable --now docker
systemctl is-active docker      # active
systemctl is-enabled docker     # enabled
```

**2.3** Still on the server:
```bash
sudo docker run -d --name web --restart unless-stopped \
  -p 80:80 -v /srv/www:/usr/share/nginx/html:ro nginx:alpine
sudo docker ps
```
Then open `http://<public-ip>` (if your browser jumps to `https://`, type the
`http://` in by hand). Made a mistake in the `docker run`? `sudo docker rm -f web`
and run it again.

**2.4** `exit`, then **Instance state** → **Stop instance** → wait for **Stopped** →
**Instance state** → **Start instance**. Copy the new **Public IPv4 address** into
`HostName` under `Host amigos-web`, then `ssh amigos-web sudo docker ps` - `web` is
`Up` without you touching Docker.

## Tier 3
**3.1** EC2 → **Network & Security** → **Elastic IPs** → **Allocate Elastic IP address**
→ **Amazon's pool of IPv4 addresses** → **Add new tag** `course` / `aws-essentials` →
**Allocate**. Tick it → **Actions** → **Associate Elastic IP address** → Resource type
**Instance** → `amigos-web` → **Associate**. Then in `~/.ssh/config`:
```
Host amigos-web
    HostName <elastic-ip>
```

**3.2** Stop and start the instance: the Elastic IP is still its address, and `ssh
amigos-web` works without touching the config.

**3.3** `./course.sh stop 02-ec2`, then EC2 → **Dashboard** → **Resources**:
**Instances (running) 0**, **Elastic IPs 0**. **Key pairs** still lists `amigos-key` - on purpose.

### Answers
1. The **EBS volume** (its disk, by the GB-month), and any **Elastic IP** (by the
   hour). No compute charge while it is stopped. Terminate it to stop paying for the disk.
2. Security groups are **stateful**: a connection allowed in is tracked, and its
   replies are allowed out automatically. (Outbound rules are for connections the
   server *starts*, like `dnf install` or `docker pull`.)
3. User data runs at the **first boot** of the instance only - cloud-init records
   that it already ran. Terminate and launch a new one, or run the commands yourself
   over SSH.
4. From the **instance metadata service** at `169.254.169.254`, which only the
   server itself can reach. User data first asks for a token (IMDSv2), then reads
   `instance-id`, `instance-type` and `placement/availability-zone`. Later, in
   section 04, the same service hands a server its IAM role's credentials.
5. Every bot on the internet can then reach your SSH server: it fills your logs with
   login attempts, and the day sshd has a security bug, or a weak key slips in, they
   are the first to try it. Allowing only your IP means nobody else can even knock.
6. `systemctl enable docker` makes the Docker daemon start at boot, and `--restart
   unless-stopped` makes Docker start the `web` container whenever the daemon starts
   (unless you stopped it yourself with `docker stop`). Without either one, the site
   stays down after a reboot.
7. A new server has a new **host key**, but `known_hosts_amigos` still remembers the
   old server's key for that address - exactly what a man-in-the-middle attack would
   look like, so SSH refuses. You *know* you replaced the server, so forget the old
   key: `ssh-keygen -R <elastic-ip> -f ~/.ssh/known_hosts_amigos`, then `ssh
   amigos-web` again.
