# Solutions - EBS and AMIs

The AWS console changes its layout from time to time. If a button below has moved,
search for the page by name in the console's search bar: the goal of each step is
what matters, not the exact click path.

## Tier 1
**1.1** EC2 → **Instances** → **Launch instances**: name `amigos-data` → **Add
additional tags** → `course` / `aws-essentials` (Instances and Volumes) → **Amazon
Linux 2023 AMI** → `t3.micro` → key pair `amigos-key` → **Network settings** →
**Edit** → **Auto-assign public IP** **Enable**, **Select existing security group** →
`web-sg` → **Launch instance**. Then click the instance → **Details** →
**Availability Zone**, e.g. `us-east-1b`.

**1.2** EC2 → **Elastic Block Store** → **Volumes** → **Create volume** → Volume type
**General Purpose SSD (gp3)**, Size `2`, Availability Zone *amigos-data's zone* →
**Add tag** `Name` / `data-vol` and `course` / `aws-essentials` → **Create volume**.
Wait for **Available**, then tick it → **Actions** → **Attach volume** → Instance
`amigos-data`, Device name `/dev/sdf` → **Attach volume**.

Created it in the wrong zone? **Actions** → **Delete volume**, and create it again.
(To really move a volume to another zone: snapshot it, and create a volume from the
snapshot in the new zone.)

**1.3** Add `Host amigos-data` / `HostName <public-ip>` to `~/.ssh/config`, `ssh
amigos-data`, then the commands from the README. Check twice with `lsblk` that you
format the **empty 2G disk** - `mkfs` on the root disk destroys the server.

**1.4** The commands from the README. `cat /etc/fstab` should end with a line like:
```
UUID=6c1f...e2  /data  xfs  defaults,nofail  0  2
```
If `sudo mount -a` prints an error, fix the line before you reboot: `sudo nano
/etc/fstab`.

**1.5** `sudo reboot`, wait a minute, `ssh amigos-data 'df -h /data; cat /data/notes.txt'`.

## Tier 2
**2.1** EC2 → **Volumes** → tick `data-vol` → **Actions** → **Create snapshot** →
Description `before the accident` → **Add tag** `Name` / `data-snap` and `course` /
`aws-essentials` → **Create snapshot**. EC2 → **Snapshots**: wait for **Completed**.

**2.2** `ssh amigos-data 'sudo rm /data/notes.txt'`. EC2 → **Snapshots** → tick
`data-snap` → **Actions** → **Create volume from snapshot** → Availability Zone
*amigos-data's zone* → **Add tag** `Name` / `data-restore` → **Create volume**. Then
**Volumes** → `data-restore` → **Actions** → **Attach volume** → `amigos-data`,
`/dev/sdg`. On the server, the README's commands. Afterwards: **Volumes** →
`data-restore` → **Actions** → **Detach volume**. (`stop` deletes it later.)

Mount says *wrong fs type, bad option, bad superblock*? You left out `nouuid`, or
picked the wrong disk - `lsblk -o NAME,SIZE,SERIAL` shows which is which.

**2.3** EC2 → **Volumes** → tick `data-vol` → **Actions** → **Modify volume** → Size
`4` → **Modify** → **Modify**. The state shows **in-use - optimizing**; you don't have
to wait for it to finish. On the server: `lsblk /dev/nvme1n1` (4G), `sudo xfs_growfs
/data`, `df -h /data` (4.0G). For an ext4 filesystem the command would be `sudo
resize2fs /dev/nvme1n1`.

## Tier 3
**3.1** The README's commands on `amigos-data`, then `http://<public-ip>`. If your
browser jumps to `https://`, type `http://` in by hand.

**3.2** EC2 → **Instances** → tick `amigos-data` → **Actions** → **Image and
templates** → **Create image** → Image name `amigos-web-ami`, Image description `nginx
in Docker, ready to go` → under **Image volumes**, **Remove** the 4 GiB EBS volume (keep
the 8 GiB root) → **Tags**: **Tag image and snapshots together** → **Add new tag**
`course` / `aws-essentials` → **Create image**. EC2 → **Images** → **AMIs**: wait for
**Available**.

**3.3** EC2 → **Launch instances** → name `amigos-clone`, tag `course` /
`aws-essentials` → **Application and OS Images** → **My AMIs** → **Owned by me** →
`amigos-web-ami` → `t3.micro`, `amigos-key`, **Edit** network: public IP **Enable**,
`web-sg` → **Launch instance**. When it is **Running**, open its
`http://<public-ip>`. Want to look inside? Add `Host amigos-clone` to your config:
`ssh amigos-clone 'sudo docker ps; df -h /data'` - the container runs, and `/data`
is just a folder on the root disk.

**3.4** `./course.sh stop 05-ebs-amis`, then check **Instances**, **Volumes**,
**Snapshots** and **AMIs** in us-east-1.

### Answers
1. An EBS volume is stored in one availability zone, next to the servers that use
   it, so it is fast. It can only attach to a server in that zone. To move the data:
   snapshot the volume (snapshots are regional), then create a new volume from the
   snapshot in the other zone.
2. The root volume is deleted with it (**Delete on termination** is on for root
   volumes by default). `data-vol` is not: it becomes **Available**, keeps its data,
   and keeps billing until you delete it or attach it to another server.
3. Device names are given out in the order disks are found, and that order can change
   between boots or when you add a disk - `nvme1n1` today can be `nvme2n1` tomorrow.
   The UUID is written inside the filesystem itself, so it always points at the
   right disk.
4. A server that can't mount an fstab entry without `nofail` stops booting and drops
   to emergency mode - with no SSH to fix it. You saw it pay off in 3.3: the clone's
   fstab lists `/data`, there is no data disk, and it booted fine.
5. Two layers: the **volume** (the disk) grew, but the **filesystem** on it still has
   its old size. `xfs_growfs` (XFS) or `resize2fs` (ext4) stretches it to fill the disk.
6. A **snapshot** is a backup of one volume. An **AMI** is one or more snapshots (the
   server's disks) plus what you need to boot them - architecture, root device, boot
   mode - so you can launch servers from it.
7. The restored volume is a block-for-block copy of `data-vol`, so its filesystem has
   the same UUID. XFS refuses to mount a second filesystem with a UUID that is
   already mounted, unless you pass `nouuid`.
