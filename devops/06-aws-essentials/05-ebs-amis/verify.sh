#!/usr/bin/env bash
# Grades "05 - EBS and AMIs" against the student's real AWS account.
#
# Runs inside the AWS checker container, after lib/aws.sh. It reads EC2 (instances,
# volumes, snapshots, images) and visits both web servers like any browser would. To
# look inside amigos-data it logs in over SSH itself, with a throwaway key handed to
# the server through EC2 Instance Connect - never your amigos-key - and only reads:
# what is mounted on /data, /etc/fstab, and whether /data/notes.txt exists. Nothing
# is changed. At the end it lists everything that is still billing.

require_login \
  "1.1 instance 'amigos-data' is running (Amazon Linux 2023, t3.micro, amigos-key)" \
  "1.2 volume 'data-vol' is attached to amigos-data" \
  "1.3 data-vol is formatted and mounted on /data, with notes.txt" \
  "1.4 /etc/fstab mounts data-vol on /data at boot, by UUID, with nofail" \
  "2.1 snapshot 'data-snap' of data-vol is completed" \
  "2.2 a volume was restored from data-snap, and notes.txt is back" \
  "2.3 data-vol and its filesystem were grown to 4 GiB" \
  "3.1 amigos-data serves your page" \
  "3.2 your AMI 'amigos-web-ami' is available" \
  "3.3 'amigos-clone', launched from amigos-web-ami, serves the page"

FREE_TYPES=" t3.micro t3.small t4g.micro t4g.small t2.micro "
MY_IP="$(curl -s -m 5 https://checkip.amazonaws.com 2>/dev/null | tr -d '[:space:]')"
GiB=1073741824

tag_of() { jq -r --arg k "$1" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""'; }
# page <url> -> sets CODE (HTTP status, or 000) and RC (curl exit code: 7 refused, 28 timeout)
page() {
  CODE="$(curl -s -o /tmp/page -w '%{http_code}' --connect-timeout 8 --max-time 15 "$1" 2>/dev/null)"
  RC=$?
}
web_hint() { # web_hint <id> <ip>: why the page did not load
  case "$RC" in
    7)  no "$1 nothing listens on port 80 at $2 - is the container 'web' running with -p 80:80?" ;;
    28) no "$1 no answer from $2 - does the server's security group allow HTTP (80) from 0.0.0.0/0?" ;;
    *)  if [ "$CODE" = 200 ]; then no "$1 http://$2 shows a page, but not yours - is /srv/www/index.html there, and mounted with -v?"
        else no "$1 http://$2 answered ${CODE:-nothing} - expected the 'amigos-web-ami' page"; fi ;;
  esac
}

echo "Tier 1 - A second disk"

data="$(instances_named amigos-data)"
n="$(jq length <<<"$data")"
I="$(jq -c '.[0] // {}' <<<"$data")"
IID="$(jq -r '.InstanceId // empty' <<<"$I")"
STATE="$(jq -r '.State.Name // empty' <<<"$I")"
IP="$(jq -r '.PublicIpAddress // empty' <<<"$I")"
AZ="$(jq -r '.Placement.AvailabilityZone // empty' <<<"$I")"

if [ "$n" -eq 0 ]; then
  no "1.1 launch an instance named amigos-data (EC2 → Launch instances)"
elif [ "$n" -gt 1 ]; then
  no "1.1 you have $n instances named amigos-data - terminate the extras (each one is billed)"
else
  type="$(jq -r '.InstanceType' <<<"$I")"
  ami="$(aws ec2 describe-images --image-ids "$(jq -r '.ImageId' <<<"$I")" --query 'Images[0].Name' --output text 2>/dev/null)"
  keyname="$(jq -r '.KeyName // ""' <<<"$I")"
  sgids="$(jq -r '[.SecurityGroups[]?.GroupId] | join(" ")' <<<"$I")"
  # shellcheck disable=SC2086
  ssh_world="$(aws ec2 describe-security-groups --group-ids $sgids --output json 2>/dev/null | jq -r '
    [.SecurityGroups[]?.IpPermissions[]? | select(.IpProtocol == "-1" or (.IpProtocol == "tcp" and .FromPort <= 22 and .ToPort >= 22))
     | select(([.IpRanges[]?.CidrIp] | index("0.0.0.0/0")) != null or ([.Ipv6Ranges[]?.CidrIpv6] | index("::/0")) != null)] | length > 0')"
  if [ "$STATE" != running ]; then
    no "1.1 amigos-data is $STATE - start it (Instance state → Start instance)"
  elif [[ "$FREE_TYPES" != *" $type "* ]]; then
    no "1.1 amigos-data is a $type - use t3.micro"
  elif [ -n "$ami" ] && [ "$ami" != None ] && { [[ "$ami" != al2023-ami-* ]] || [[ "$ami" == al2023-ami-minimal* ]]; }; then
    no "1.1 amigos-data runs $ami - launch it again from Amazon Linux 2023 (the standard AMI)"
  elif [ "$keyname" != amigos-key ]; then
    no "1.1 amigos-data was launched with key pair '${keyname:-none}', not amigos-key - terminate it and launch again"
  elif [ "$ssh_world" = true ]; then
    no "1.1 amigos-data's security group has SSH open to the whole internet - change the source to My IP (${MY_IP:-your IP}/32)"
  elif [ "$(tag_of "$TAG_KEY" <<<"$I")" != "$TAG_VALUE" ]; then
    no "1.1 tag amigos-data with course = aws-essentials (Tags tab → Manage tags)"
  else
    ok "1.1 instance 'amigos-data' is running ($type, Amazon Linux 2023, amigos-key, in $AZ)"
  fi
fi

vols="$(aws ec2 describe-volumes --filters Name=tag:Name,Values=data-vol --output json 2>/dev/null)"
[ -n "$vols" ] || vols='{}'
nv="$(jq '.Volumes | length' <<<"$vols" 2>/dev/null || echo 0)"
V="$(jq -c '.Volumes[0] // {}' <<<"$vols")"
VOL="$(jq -r '.VolumeId // empty' <<<"$V")"
VSIZE="$(jq -r '.Size // 0' <<<"$V")"
VAZ="$(jq -r '.AvailabilityZone // empty' <<<"$V")"
attached_to="$(jq -r '[.Attachments[]? | select(.State == "attached" or .State == "attaching") | .InstanceId][0] // ""' <<<"$V")"

if [ "${nv:-0}" -eq 0 ]; then
  no "1.2 create a volume tagged Name = data-vol (EC2 → Volumes → Create volume, gp3, 2 GiB)"
elif [ "$nv" -gt 1 ]; then
  no "1.2 you have $nv volumes named data-vol - delete the extras (each one is billed)"
elif [ -n "$AZ" ] && [ "$VAZ" != "$AZ" ]; then
  no "1.2 data-vol is in $VAZ but amigos-data is in $AZ - a volume can't leave its zone: delete it and create it again in $AZ"
elif [ "$(tag_of "$TAG_KEY" <<<"$V")" != "$TAG_VALUE" ]; then
  no "1.2 tag data-vol with course = aws-essentials (Volumes → data-vol → Tags)"
elif [ -z "$IID" ] || [ "$attached_to" != "$IID" ]; then
  if [ -n "$attached_to" ]; then no "1.2 data-vol is attached to $attached_to, not amigos-data"
  else no "1.2 attach data-vol to amigos-data (Volumes → data-vol → Actions → Attach volume)"; fi
else
  ok "1.2 volume 'data-vol' ($VOL, ${VSIZE} GiB) is attached to amigos-data"
fi

# One look inside amigos-data. Prints connected=yes, and for whatever is mounted on
# /data: its filesystem, disk serial (the volume ID without the dash), UUID and size;
# notes=yes when /data/notes.txt exists; the /data line of /etc/fstab; the 'web'
# container's state.
PROBE="$(cat <<'SH'
echo connected=yes
src=$(findmnt -n -o SOURCE /data 2>/dev/null)
if [ -n "$src" ]; then
  echo "fstype=$(findmnt -n -o FSTYPE /data)"
  echo "serial=$(lsblk -n -d -o SERIAL "$src" 2>/dev/null | tr -d ' ')"
  echo "uuid=$(blkid -s UUID -o value "$src" 2>/dev/null)"
  echo "fssize=$(df -B1 --output=size /data 2>/dev/null | tail -1 | tr -d ' ')"
fi
[ -f /data/notes.txt ] && echo notes=yes
awk '$1 !~ /^#/ && $2 == "/data" { print "fstab=" $1 "|" $3 "|" $4; exit }' /etc/fstab
command -v docker >/dev/null && echo "web=$(docker inspect web --format '{{.State.Status}}' 2>/dev/null)"
true
SH
)"
if [ "$STATE" = running ] && [ -n "$IP" ]; then ssh_probe "$IID" "$IP" "$PROBE"; else PROBE_OUT="" PROBE_ERR=""; fi
field() { sed -n "s/^$1=//p" <<<"$PROBE_OUT" | head -1; }
CONNECTED="$(field connected)"
fstype="$(field fstype)"; serial="$(field serial)"; uuid="$(field uuid)"; fssize="$(field fssize)"
IFS='|' read -r fs_dev fs_type fs_opts <<<"$(field fstab)"
inside_hint() { # inside_hint <id>: why the checker can't look inside
  if [ "$STATE" != running ]; then no "$1 the checker looks inside amigos-data over SSH - it must be running (1.1)"
  elif [ -z "$IP" ]; then no "$1 amigos-data has no public IP - launch it again with Auto-assign public IP: Enable"
  else case "$PROBE_ERR" in
    *"timed out"*|*"Connection refused"*|*"No route"*)
      no "$1 SSH to $IP times out from this machine - the security group must allow SSH from ${MY_IP:-your IP}/32" ;;
    *) no "$1 the checker could not log in to amigos-data over SSH: ${PROBE_ERR:-no answer} - try again in a minute" ;;
  esac; fi
}

if [ "$CONNECTED" != yes ]; then
  inside_hint 1.3
elif [ -z "$fstype" ]; then
  no "1.3 nothing is mounted on /data - format and mount data-vol (sudo mkfs -t xfs, then sudo mount)"
elif [ -n "$VOL" ] && [ "$serial" != "${VOL/-/}" ]; then
  no "1.3 /data is not data-vol (it is the disk with serial ${serial:-?}) - check lsblk -o NAME,SIZE,SERIAL"
elif [ "$(field notes)" != yes ]; then
  no "1.3 /data is mounted, but /data/notes.txt is missing - write it (see 1.3), or restore it (2.2)"
else
  ok "1.3 data-vol is formatted ($fstype) and mounted on /data, with notes.txt"
fi

if [ "$CONNECTED" != yes ]; then
  inside_hint 1.4
elif [ -z "$fs_dev" ]; then
  no "1.4 /etc/fstab has no line for /data - add it (see 1.4), then test with sudo mount -a"
elif [[ "$fs_dev" != UUID=* ]]; then
  no "1.4 fstab mounts /data by '$fs_dev' - use UUID=..., device names can change between boots"
elif [ -n "$uuid" ] && [ "$fs_dev" != "UUID=$uuid" ]; then
  no "1.4 fstab's $fs_dev is not the disk mounted on /data (UUID=$uuid) - fix the UUID"
elif [[ ",$fs_opts," != *",nofail,"* ]]; then
  no "1.4 add nofail to the /data line in fstab (defaults,nofail) - without it a missing disk stops the server booting"
else
  ok "1.4 /etc/fstab mounts data-vol on /data at boot, by UUID, with nofail"
fi

echo "Tier 2 - Back it up, restore it, grow it"

snaps="$(aws ec2 describe-snapshots --owner-ids self --filters Name=tag:Name,Values=data-snap --output json 2>/dev/null)"
[ -n "$snaps" ] || snaps='{}'
S="$(jq -c --arg v "$VOL" '(.Snapshots // []) | (map(select(.VolumeId == $v)) + .)[0] // {}' <<<"$snaps")"
SNAP="$(jq -r '.SnapshotId // empty' <<<"$S")"
if [ -z "$SNAP" ]; then
  no "2.1 snapshot data-vol, tagged Name = data-snap (Volumes → data-vol → Actions → Create snapshot)"
elif [ "$(jq -r '.VolumeId' <<<"$S")" != "$VOL" ]; then
  no "2.1 data-snap is a snapshot of $(jq -r '.VolumeId' <<<"$S"), not of data-vol"
elif [ "$(jq -r '.State' <<<"$S")" != completed ]; then
  no "2.1 data-snap is $(jq -r '.State' <<<"$S") ($(jq -r '.Progress // ""' <<<"$S")) - wait for Completed and check again"
elif [ "$(tag_of "$TAG_KEY" <<<"$S")" != "$TAG_VALUE" ]; then
  no "2.1 tag data-snap with course = aws-essentials (Snapshots → data-snap → Tags)"
else
  ok "2.1 snapshot 'data-snap' ($SNAP) of data-vol is completed"
fi

restored=0
[ -n "$SNAP" ] && restored="$(aws ec2 describe-volumes --filters "Name=snapshot-id,Values=$SNAP" \
  --query 'length(Volumes)' --output text 2>/dev/null || echo 0)"
if [ -z "$SNAP" ]; then
  no "2.2 a volume restored from data-snap - take the snapshot first (2.1)"
elif [ "${restored:-0}" -lt 1 ] 2>/dev/null; then
  no "2.2 create a volume from data-snap (Snapshots → data-snap → Actions → Create volume from snapshot)"
elif [ "$CONNECTED" != yes ]; then
  inside_hint 2.2
elif [ "$(field notes)" != yes ]; then
  no "2.2 /data/notes.txt is still missing - mount the restored volume on /restore and copy it back (see 2.2)"
else
  ok "2.2 a volume was restored from data-snap, and notes.txt is back"
fi

if [ -z "$VOL" ]; then
  no "2.3 data-vol and its filesystem were grown to 4 GiB - create data-vol first (1.2)"
elif [ "$VSIZE" -lt 4 ] 2>/dev/null; then
  no "2.3 data-vol is $VSIZE GiB - grow it to 4 (Volumes → data-vol → Actions → Modify volume)"
elif [ "$CONNECTED" != yes ]; then
  inside_hint 2.3
elif [ -z "$fssize" ] || [ "$serial" != "${VOL/-/}" ]; then
  no "2.3 mount data-vol on /data first (1.3)"
elif [ "$fssize" -lt $((GiB * 7 / 2)) ]; then
  no "2.3 the disk is $VSIZE GiB but the filesystem on /data is still $((fssize / 1048576)) MiB - run: sudo xfs_growfs /data"
else
  ok "2.3 data-vol and its filesystem were grown to $VSIZE GiB"
fi

echo "Tier 3 - Your own machine image"

if [ "$STATE" != running ] || [ -z "$IP" ]; then
  no "3.1 amigos-data serves your page - it must be running (1.1)"
else
  page "http://$IP/"
  if [ "$CODE" = 200 ] && grep -q 'amigos-web-ami' /tmp/page; then
    ok "3.1 amigos-data serves your page at http://$IP"
  elif [ "$CONNECTED" = yes ] && [ "$(field web)" = "" ]; then
    no "3.1 no container named 'web' on amigos-data - install Docker and run it (see 3.1)"
  else
    web_hint 3.1 "$IP"
  fi
fi

imgs="$(aws ec2 describe-images --owners self --filters Name=name,Values=amigos-web-ami --output json 2>/dev/null)"
[ -n "$imgs" ] || imgs='{}'
A="$(jq -c '.Images[0] // {}' <<<"$imgs")"
AMI_ID="$(jq -r '.ImageId // empty' <<<"$A")"
ast="$(jq -r '.State // empty' <<<"$A")"
nebs="$(jq '[.BlockDeviceMappings[]? | select(.Ebs)] | length' <<<"$A")"
if [ -z "$AMI_ID" ]; then
  no "3.2 create an image named amigos-web-ami from amigos-data (Actions → Image and templates → Create image)"
elif [ "$ast" = pending ]; then
  no "3.2 amigos-web-ami is still pending - an image takes a few minutes, check again soon"
elif [ "$ast" != available ]; then
  no "3.2 amigos-web-ami is $ast - deregister it and create it again"
elif [ "$(tag_of "$TAG_KEY" <<<"$A")" != "$TAG_VALUE" ]; then
  no "3.2 tag amigos-web-ami with course = aws-essentials (AMIs → amigos-web-ami → Tags)"
else
  ok "3.2 your AMI 'amigos-web-ami' ($AMI_ID) is available"
  [ "${nebs:-1}" -gt 1 ] && note "it holds $nebs disks - next time remove the data volume under Image volumes: an image is the server, not its data"
fi

clones="$(instances_named amigos-clone)"
nc="$(jq length <<<"$clones")"
C="$(jq -c '.[0] // {}' <<<"$clones")"
CST="$(jq -r '.State.Name // empty' <<<"$C")"
CIP="$(jq -r '.PublicIpAddress // empty' <<<"$C")"
if [ "$nc" -eq 0 ]; then
  no "3.3 launch an instance named amigos-clone from My AMIs → amigos-web-ami"
elif [ "$nc" -gt 1 ]; then
  no "3.3 you have $nc instances named amigos-clone - terminate the extras"
elif [ -z "$AMI_ID" ] || [ "$(jq -r '.ImageId' <<<"$C")" != "$AMI_ID" ]; then
  no "3.3 amigos-clone was not launched from amigos-web-ami - terminate it, and launch it from My AMIs"
elif [ "$CST" != running ]; then
  no "3.3 amigos-clone is $CST - start it"
elif [ "$(tag_of "$TAG_KEY" <<<"$C")" != "$TAG_VALUE" ]; then
  no "3.3 tag amigos-clone with course = aws-essentials"
elif [ -z "$CIP" ]; then
  no "3.3 amigos-clone has no public IP - launch it again with Auto-assign public IP: Enable"
else
  page "http://$CIP/"
  if [ "$CODE" = 200 ] && grep -q 'amigos-web-ami' /tmp/page; then
    ok "3.3 'amigos-clone', launched from amigos-web-ami, serves the page at http://$CIP"
  else
    web_hint 3.3 "$CIP"
  fi
fi

score
[[ $fail -eq 0 ]] && echo "🎉 A data disk that survives reboots, a backup you restored, a disk grown live - and a server image that boots ready to work."

# ---- what is billing right now --------------------------------------------------
running="$(jq -r -s '[.[][] | select(.State.Name == "running" or .State.Name == "pending") | (.Tags[]? | select(.Key == "Name") | .Value)] | join(" ")' <<<"$data $clones")"
allvols="$(aws ec2 describe-volumes --filters "Name=tag:Name,Values=data-vol,data-restore" --query 'Volumes[].[Tags[?Key==`Name`].Value | [0], Size, State]' --output text 2>/dev/null | awk '{printf "%s%s (%s GiB, %s)", sep, $1, $2, $3; sep=", "}')"
nsnaps="$(aws ec2 describe-snapshots --owner-ids self --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" --query 'length(Snapshots)' --output text 2>/dev/null)"
if [ -n "$running$allvols$AMI_ID" ] || [ "${nsnaps:-0}" -gt 0 ] 2>/dev/null; then
  echo
  echo "⚠️  Still billing in us-east-1:"
  [ -n "$running" ] && echo "   - running servers: $running  (about \$0.015/hour each)"
  [ -n "$allvols" ] && echo "   - volumes: $allvols  (\$0.08 per GiB-month)"
  [ "${nsnaps:-0}" -gt 0 ] 2>/dev/null && echo "   - snapshots: $nsnaps  (\$0.05 per GiB-month)"
  [ -n "$AMI_ID" ] && echo "   - your AMI amigos-web-ami: $AMI_ID  (billed as its snapshots)"
  echo "   When you are done: ${LAUNCHER:-./course.sh} stop 05-ebs-amis"
fi
exit 0
