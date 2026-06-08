# Solutions - Users & Groups

## Tier 1

**1.1** `/opt` is owned by root, so you need elevated privileges:
```bash
sudo mkdir /opt/acme
```

**1.2** `-m` creates the user's home directory at `/home/alice`:
```bash
sudo useradd -m alice
sudo passwd alice          # interactive; sets her login password
```

## Tier 2

**2.1**
```bash
sudo groupadd developers
```

**2.2** `gpasswd -a` **a**dds a user to a group:
```bash
sudo gpasswd -a alice developers
id -nG alice               # alice ... developers
```

**2.3** The `sudo` group is what grants admin rights on Ubuntu:
```bash
sudo adduser alice sudo
# equivalent: sudo gpasswd -a alice sudo
```

## Tier 3

**3.1** Onboard and group in a few commands:
```bash
sudo useradd -m bob
sudo useradd -m carol
sudo groupadd ops
sudo gpasswd -M alice,bob,carol ops    # -M sets the entire member list
```

**3.2** `gpasswd -d` **d**eletes a user from a group (account untouched):
```bash
sudo gpasswd -d carol ops
```

**3.3**
```bash
sudo groupdel legacy
```

### Answers to the self-check

1. `sudo` runs a single command with **root (superuser) privileges**. It's
   restricted because root can do anything - including destroy the system - so
   only trusted users (members of the `sudo` group) get it.
2. `-m` makes the user's **home directory**; without it the account has nowhere to
   store its files/config.
3. Add them to the **`sudo` group** (`adduser USER sudo`). They can then use `sudo`
   for admin tasks without *being* root.
4. `-a` **adds** one user to a group, `-d` **deletes** one user from a group, `-M`
   **sets the complete member list** in one shot (replacing whatever was there).

---

## Quick reference

| Goal | Command |
|------|---------|
| Run a command as root | `sudo <cmd>` (repeat last as root: `sudo !!`) |
| Create user + home | `sudo useradd -m NAME` |
| Set a password | `sudo passwd NAME` |
| Switch user | `su NAME` |
| Create / delete group | `sudo groupadd G` / `sudo groupdel G` |
| Add / remove from group | `sudo gpasswd -a USER G` / `sudo gpasswd -d USER G` |
| Set whole member list | `sudo gpasswd -M u1,u2 G` |
| Grant admin (sudo) | `sudo adduser USER sudo` |
| Who's in what | `id -nG USER` · `cat /etc/group` · `cat /etc/passwd` |
