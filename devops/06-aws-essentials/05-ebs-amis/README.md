# 05 - EBS and AMIs

> Maps to **AWS Essentials - Section 5: EBS and AMIs**
> (EBS volumes, volume types, availability zones, attaching, formatting and mounting a disk, fstab, snapshots, restoring, resizing, AMIs, launching from your own image)

Every EC2 server you have launched so far had one disk, made for you at launch and
thrown away when the server was terminated. Real servers keep their data on disks
that live on their own: you can detach them, back them up, copy them, grow them, and
move them to a new server when the old one dies. On AWS that disk is an **EBS
volume**, its backup is a **snapshot**, and a snapshot of a whole server that you can
launch again and again is an **AMI** - your own machine image.

In this section you add a data disk to a server and set it up over SSH the way you
would on any Linux box, back it up, break things, restore them, and grow the disk
while the server keeps running. Then you bake a web server into an image and launch
a copy of it that is ready the moment it boots - no setup at all.

## The building blocks

- **EBS volume** - a network disk for one EC2 server. It lives in **one availability
  zone** and can only be attached to servers in that same zone. You pay per GB per
  month, whether it is attached or not.
- **Volume type** - **gp3** (general purpose SSD) is the default and right for almost
  everything. There are faster (io2) and cheaper, slower (st1, sc1) types.
- **Root volume** - the disk the server boots from. It is deleted with the server by
  default (**Delete on termination**). A volume you attach yourself is not.
- **Device name and filesystem** - an attached volume is just a raw disk, like a new
  hard drive. You **format** it (put a filesystem on it), **mount** it on a folder,
  and add it to **`/etc/fstab`** so it is mounted again after every reboot.
- **Snapshot** - a point-in-time backup of a volume, stored by AWS outside the zone.
  Snapshots are **incremental**: only blocks that changed since the last one are
  stored. You restore by creating a new volume from a snapshot.
- **AMI** (Amazon Machine Image) - snapshots of a server's disks plus the settings to
  boot them. Amazon Linux 2023 is an AMI; you can make your own from any server.

## How to use this set

From the `devops/06-aws-essentials/` folder:

```bash
./course.sh start  05-ebs-amis   # creates security group web-sg if missing
./course.sh verify 05-ebs-amis   # check your work
./course.sh stop   05-ebs-amis   # terminate both servers, delete the volumes,
                                 # snapshots and your AMI (amigos-key is kept)

# Windows (PowerShell or Command Prompt): course.cmd instead of ./course.sh
```

You need your key pair `amigos-key` and the `Host amigos-*` block in `~/.ssh/config`
from section 02 (tasks 1.2 and 2.1). Skipped section 02? Do those two tasks first.
`start` creates the security group `web-sg` (HTTP from anywhere, SSH from your IP) if
you don't have it.

Sign in to the console as **amigos-admin**, region **us-east-1**.

> ⚠️ **This section costs money by the hour.** Two `t3.micro` servers with public
> IPs are about **3 cents an hour**. Disks, snapshots and your AMI cost a few cents a
> *month* each - small, but they never stop on their own: a forgotten snapshot or
> AMI bills quietly for years. **Do the section in one sitting, then run
> `./course.sh stop 05-ebs-amis`.**

---

## Tier 1 - A second disk *(hint: EC2 → Instances, then Elastic Block Store → Volumes)*

**1.1 (graded)** Launch a server named `amigos-data`: **Amazon Linux 2023**,
`t3.micro`, key pair `amigos-key`, **Select existing security group** → `web-sg`,
**Auto-assign public IP: Enable**, tag `course` = `aws-essentials`. When it is
running, note its **Availability Zone** (the instance's **Details** tab, e.g.
`us-east-1b`). You need it next.

**1.2 (graded)** Create a disk and plug it in. EC2 → **Volumes** → **Create volume**:

- **Volume type** `gp3`, **Size** `2` GiB
- **Availability Zone**: the **same one as amigos-data** - a volume in another zone
  can never be attached to it
- **Tags**: `Name` = `data-vol`, `course` = `aws-essentials`

Then select `data-vol` → **Actions** → **Attach volume** → instance `amigos-data`,
device name `/dev/sdf` → **Attach volume**. Its state becomes **In-use**.

**1.3 (graded)** Format and mount it. Add the server to `~/.ssh/config`:

```
Host amigos-data
    HostName <public-ip>
```

Then `ssh amigos-data` and:

```bash
lsblk -o NAME,SIZE,SERIAL,MOUNTPOINTS
```

Two disks. `nvme0n1` (8G, its partitions mounted on `/` and `/boot/efi`) is the
root disk - **never format that one**. The 2G one, `nvme1n1`, is `data-vol`: its SERIAL is the volume ID without the
dash (`vol0abc...` for `vol-0abc...`). The name you chose, `/dev/sdf`, is not the
name Linux uses on this kind of server - always check with `lsblk`.

```bash
sudo mkfs -t xfs /dev/nvme1n1              # put a filesystem on the new disk
sudo mkdir /data
sudo mount /dev/nvme1n1 /data              # the disk is now the /data folder
echo "written on $(date)" | sudo tee /data/notes.txt
df -h /data                                # 2.0G, mounted on /data
```

**1.4 (graded)** Make it survive a reboot. A `mount` lasts until the next reboot;
`/etc/fstab` is the list Linux mounts at every boot. Add `/data` to it - by the
disk's **UUID**, which never changes, not by its name, which can:

```bash
UUID=$(sudo blkid -s UUID -o value /dev/nvme1n1)
echo "UUID=$UUID  /data  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo umount /data && sudo mount -a   # mount all of fstab: the test
df -h /data                                # back on /data
```

> **`nofail`** means "boot even if this disk is missing". Without it, a server whose
> data disk is gone (detached, or not in the image - Tier 3) never finishes booting,
> and you can't SSH in to fix it. A broken fstab line is the classic way to lock
> yourself out of a server: always test with `mount -a` before you reboot.

**1.5 (drill)** `sudo reboot`, wait a minute, `ssh amigos-data` again: `df -h /data`
and `cat /data/notes.txt` - mounted and intact.

---

## Tier 2 - Back it up, restore it, grow it *(hint: Volumes → Actions, then Snapshots)*

**2.1 (graded)** Take a backup. EC2 → **Volumes** → `data-vol` → **Actions** →
**Create snapshot** → description `before the accident`, tags `Name` = `data-snap`,
`course` = `aws-essentials` → **Create snapshot**. EC2 → **Snapshots**: it goes from
**Pending** to **Completed** in a minute or two.

**2.2 (graded)** Have an accident, then recover. On the server:

```bash
sudo rm /data/notes.txt                    # gone
```

A snapshot is not a folder you can open. You restore it as a **new volume**: EC2 →
**Snapshots** → `data-snap` → **Actions** → **Create volume from snapshot** → the
**same zone as amigos-data**, tag `Name` = `data-restore` → **Create volume**. Attach
it to `amigos-data` as `/dev/sdg`. Then on the server:

```bash
lsblk -o NAME,SIZE,SERIAL,MOUNTPOINTS   # nvme2n1 is data-restore
sudo mkdir /restore
sudo mount -o ro,nouuid /dev/nvme2n1 /restore
sudo cp /restore/notes.txt /data/          # the file is back
cat /data/notes.txt
sudo umount /restore
```

Then **detach** `data-restore` (Volumes → **Actions** → **Detach volume**). You no
longer need it.

> `nouuid`: the restored disk is an exact copy, **UUID included**, and XFS refuses to
> mount two filesystems with the same UUID unless you tell it to. That is also why
> you detach the copy: at the next boot, fstab's `UUID=` could pick either one.

**2.3 (graded)** Grow the disk without stopping anything. EC2 → **Volumes** →
`data-vol` → **Actions** → **Modify volume** → **Size** `4` → **Modify**. Then on the
server:

```bash
lsblk /dev/nvme1n1                         # 4G - the disk grew
df -h /data                                # still 2.0G: the filesystem
sudo xfs_growfs /data                      # grow it to fill the disk
df -h /data                                # 4.0G
```

> The server kept running the whole time. Volumes can only **grow**, never shrink,
> and you can change a volume again only after about 6 hours - so think before you
> pick a size.

---

## Tier 3 - Your own machine image *(hint: Instances → Actions → Image and templates)*

**3.1 (graded)** Turn `amigos-data` into a web server - the same as section 02, so
the commands are short this time. On the server:

```bash
sudo dnf install -y docker
sudo systemctl enable --now docker
sudo mkdir -p /srv/www
echo '<h1>Hello from amigos-web-ami</h1>' | sudo tee /srv/www/index.html
sudo docker run -d --name web --restart unless-stopped -p 80:80 \
  -v /srv/www:/usr/share/nginx/html:ro nginx:alpine
```

Open `http://<public-ip>` in your browser: *Hello from amigos-web-ami*.

**3.2 (graded)** Bake it into an image. EC2 → **Instances** → `amigos-data` →
**Actions** → **Image and templates** → **Create image**:

- **Image name** `amigos-web-ami`, description `nginx in Docker, ready to go`
- **Image volumes**: keep the 8 GiB root volume, **remove** the 4 GiB data volume -
  the image is the server, not its data
- **Tags**: **Tag image and snapshots together**, `course` = `aws-essentials`

→ **Create image**. The server reboots, so the disk is copied in a clean state. EC2 →
**AMIs**: `amigos-web-ami` goes from **Pending** to **Available** in a few minutes.
Behind it, under **Snapshots**, is a new snapshot of the root disk.

**3.3 (graded)** Launch a copy that needs no setup. EC2 → **Launch instances** →
name `amigos-clone`, tag `course` = `aws-essentials` → **Application and OS Images**
→ **My AMIs** → `amigos-web-ami` → `t3.micro`, `amigos-key`, `web-sg`, public IP on.
**No user data**. Launch it, wait for **Running**, and open `http://<clone-ip>`: the
same page. Nobody installed Docker or ran a container on this server - it booted
that way.

> The clone's fstab still lists `/data`, but it has no data disk. It booted anyway:
> that is `nofail` from 1.4 at work. This is how teams make servers that start in
> seconds, and how an Auto Scaling group (section 07) launches identical servers.

**3.4 (drill)** Clean up and look: `./course.sh stop 05-ebs-amis`, then EC2 →
**Instances**, **Volumes**, **Snapshots** and **AMIs** (the last two under **Images**
and **Elastic Block Store**). Nothing from this section is left. Remove the
`Host amigos-data` block from your config if you like.

All green = you can add a disk to a server and keep it mounted, back it up and
restore it, grow it without downtime, and turn a server into an image that launches
ready to work.

---

## Self-check questions

1. Why must `data-vol` be in the same availability zone as `amigos-data`? How would
   you move its data to a server in another zone?
2. You terminate `amigos-data`. What happens to its root volume, and to `data-vol`?
3. Why does fstab use the disk's UUID instead of `/dev/nvme1n1`?
4. What does `nofail` protect you from? Where did you see it pay off?
5. You grew the volume to 4 GiB but `df` still says 2. Why, and what fixes it?
6. What is the difference between a snapshot and an AMI?
7. Why did the restored disk need `nouuid` to mount?
