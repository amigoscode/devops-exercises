# Solutions - SSH

## Tier 1
**1.1** Create `~/.ssh/config` with a host alias:
```bash
mkdir -p ~/.ssh
cat > ~/.ssh/config <<'EOF'
Host myserver
    HostName 203.0.113.10
    User ubuntu
    IdentityFile ~/.ssh/mykey.pem
EOF
```

## Tier 2
**2.1**
```bash
chmod 600 ~/.ssh/config
```

## Tier 3
**3.1** Append a prod block:
```bash
cat >> ~/.ssh/config <<'EOF'

Host prod
    HostName 198.51.100.42
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/mykey.pem
EOF
```

### Answers
1. The **public** key goes on the server (`authorized_keys`); you keep the
   **private** key secret on your machine.
2. It stores host, user, port and key per alias, so `ssh myserver` replaces
   `ssh -i ~/.ssh/mykey.pem -p 22 ubuntu@203.0.113.10`.
3. SSH ignores keys/configs that others can read - loose permissions are a security
   risk, so it enforces `600` (config/private key) or `400` (a `.pem`).
