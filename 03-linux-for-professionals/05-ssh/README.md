# 05 · SSH

> Maps to **Linux for Professionals → Section 21: SSH (Secure Shell)**
> (key pairs, `ssh-keygen`, `ssh -i`, `~/.ssh/config`, AWS EC2)

SSH is how you reach every remote server. Writing a clean `~/.ssh/config` (taught in
detail in the lecture) is what's graded here. Generating your own key pair and
connecting to a cloud box (AWS EC2) are **drills** at the bottom - in the course you
get a key from AWS, so those steps need an account.

## How to use this set

```bash
make start  S=05-ssh
make verify S=05-ssh
make reset  S=05-ssh
```

---

## Tier 1 - Write an SSH config *(hint: the `Host` / `HostName` / `User` / `IdentityFile` format)*

**1.1 (graded)** Typing `ssh -i key.pem user@ip` every time is painful. Create
`~/.ssh/config` with a host alias called **`myserver`** that defines its **hostname**,
the **user** to log in as, and the **identity file** (your `.pem` key) to use - so you
could connect with just `ssh myserver`.

## Tier 2 - Lock it down *(think: the permission SSH insists on)*

**2.1 (graded)** SSH ignores a config that others can read. Set `~/.ssh/config` to the
permissions SSH expects (owner read/write only).

## Tier 3 - Add a production host *(goal only)*

**3.1 (graded)** Add a second host entry called **`prod`** to `~/.ssh/config`: user
`ubuntu`, its own hostname/IP, the SSH port, and the identity file.

## 💪 Drills (self-check - try on your own machine / an AWS account)

0. **Generate your own key pair** (the local alternative to AWS's `.pem`):
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""   # -N "" = no passphrase
   ```
   This creates the private key `id_ed25519` and public key `id_ed25519.pub`.
1. Launch an EC2 instance and create/download its `.pem` key. In the EC2 console,
   download it under **Network & Security → Key Pairs**
   ([AWS docs: create a key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html#having-ec2-create-your-key-pair)).
   Then lock it down so SSH will accept it: `chmod 400 key.pem`.
2. Connect: `ssh -i key.pem ubuntu@<public-ip>`.
3. Add it to `~/.ssh/config` and connect with just `ssh <host>`.
4. Install your **public** key on a server for password-less login - the easy way:
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@<public-ip>
   ```
   Or manually (this is exactly what `ssh-copy-id` does under the hood):
   ```bash
   cat ~/.ssh/id_ed25519.pub | ssh ubuntu@<public-ip> \
     'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys'
   ```
   Then you can `ssh ubuntu@<public-ip>` with no password - only your private key.

## Self-check questions

1. Which key goes on the server, and which do you keep secret?
2. What does `~/.ssh/config` save you from typing?
3. Why must your key / config be `600` (or the key `400`)?
