#!/usr/bin/env bash
# Grades "02 - EC2" against the student's real AWS account.
#
# Runs inside the AWS checker container, after lib/aws.sh. It reads EC2, and
# visits the web server like any browser would. To look inside the server it logs in
# over SSH itself - with a throwaway key it hands to the server through EC2 Instance
# Connect (valid for 60 seconds), never your amigos-key - and only reads: the SSH log,
# `systemctl is-active docker`, `docker inspect web`. Nothing on the server is
# changed. At the end it lists anything billed by the hour, so nothing is forgotten.

require_login \
  "1.1 security group 'web-sg': HTTP from anywhere, SSH from your IP only" \
  "1.2 key pair 'amigos-key'" \
  "1.3 instance 'amigos-web' is running (Amazon Linux 2023, t3.micro, web-sg, amigos-key)" \
  "2.1 you logged in to amigos-web over SSH with amigos-key" \
  "2.2 Docker is installed, running and starts at boot" \
  "2.3 nginx runs in a container named 'web' and serves your page" \
  "3.1 an Elastic IP is attached to amigos-web and serves the page"

FREE_TYPES=" t3.micro t3.small t4g.micro t4g.small t2.micro "
MY_IP="$(curl -s -m 5 https://checkip.amazonaws.com 2>/dev/null | tr -d '[:space:]')"

# page <url> -> sets CODE (HTTP status, or 000) and RC (curl exit code: 7 refused, 28 timeout)
page() {
  CODE="$(curl -s -o /tmp/page -w '%{http_code}' --connect-timeout 8 --max-time 15 "$1" 2>/dev/null)"
  RC=$?
}
explain_no_answer() { # explain_no_answer <id> <ip>
  case "$RC" in
    7)  no "$1 nothing listens on port 80 at $2 - is the container running with -p 80:80 (2.3)?" ;;
    28) no "$1 no answer from $2 - does web-sg allow HTTP (80) from 0.0.0.0/0?" ;;
    *)  no "$1 http://$2 answered ${CODE:-nothing} - expected your amigos-web page" ;;
  esac
}

echo "Tier 1 - Launch a server"

sg="$(aws ec2 describe-security-groups --filters Name=group-name,Values=web-sg --output json 2>/dev/null)"
[ -n "$sg" ] || sg='{}'
SG_ID="$(jq -r '.SecurityGroups[0].GroupId // empty' <<<"$sg")"
if [ -z "$SG_ID" ]; then
  no "1.1 create a security group named web-sg (EC2 → Security Groups → Create security group)"
else
  rules="$(jq -r '
    def world: ([.IpRanges[]?.CidrIp] | index("0.0.0.0/0")) != null or ([.Ipv6Ranges[]?.CidrIpv6] | index("::/0")) != null;
    def covers($p): .IpProtocol == "-1" or (.IpProtocol == "tcp" and .FromPort <= $p and .ToPort >= $p);
    (.SecurityGroups[0].IpPermissions // []) as $in
    | if any($in[]; .IpProtocol == "-1" and world) then "all"
      elif any($in[]; covers(22) and world) then "ssh-world"
      elif any($in[]; covers(80) and world) | not then "no80"
      elif any($in[]; covers(22) and ((.IpRanges // []) + (.Ipv6Ranges // []) + (.UserIdGroupPairs // []) | length > 0)) | not then "no22"
      else "ok" end' <<<"$sg")"
  ssh_from="$(jq -r '[.SecurityGroups[0].IpPermissions[]? | select(.IpProtocol == "-1" or (.IpProtocol == "tcp" and .FromPort <= 22 and .ToPort >= 22)) | .IpRanges[]?.CidrIp] | join(" ")' <<<"$sg")"
  sg_tag="$(jq -r --arg k "$TAG_KEY" '[.SecurityGroups[0].Tags[]? | select(.Key == $k) | .Value][0] // ""' <<<"$sg")"
  case "$rules" in
    all)       no "1.1 web-sg lets ALL traffic in from anywhere - delete that rule: HTTP from anywhere, SSH from your IP only" ;;
    ssh-world) no "1.1 web-sg has SSH (22) open to the whole internet - change its source to My IP (${MY_IP:-your IP}/32)" ;;
    no80)      no "1.1 add an inbound rule to web-sg: HTTP, port 80, source Anywhere-IPv4 (0.0.0.0/0)" ;;
    no22)      no "1.1 add an inbound rule to web-sg: SSH, port 22, source My IP (${MY_IP:-your IP}/32)" ;;
    ok)        if [ "$sg_tag" = "$TAG_VALUE" ]; then ok "1.1 security group 'web-sg': HTTP from anywhere, SSH from $ssh_from only"
               else no "1.1 tag web-sg with course = aws-essentials (Tags tab → Manage tags)"; fi ;;
  esac
fi

key="$(aws ec2 describe-key-pairs --key-names amigos-key --include-public-key --output json 2>/dev/null)"
[ -n "$key" ] || key='{}'
KEY_PUB="$(jq -r '.KeyPairs[0].PublicKey // empty' <<<"$key")"
KEY_FP=""
[ -n "$KEY_PUB" ] && KEY_FP="$(ssh-keygen -lf /dev/stdin <<<"$KEY_PUB" 2>/dev/null | awk '{print $2}')"
if [ -n "$KEY_PUB" ]; then
  ok "1.2 key pair 'amigos-key'"
else
  no "1.2 create a key pair named amigos-key (EC2 → Key pairs → Create key pair, ED25519, .pem)"
fi

inst="$(aws ec2 describe-instances --filters Name=tag:Name,Values=amigos-web \
  Name=instance-state-name,Values=pending,running,stopping,stopped --output json 2>/dev/null)"
[ -n "$inst" ] || inst='{}'
inst="$(jq -c '[.Reservations[]?.Instances[]?]' <<<"$inst")"
n="$(jq 'length' <<<"$inst")"
I="$(jq -c '(map(select(.State.Name == "running")) + .)[0] // {}' <<<"$inst")"   # prefer a running one
IID="$(jq -r '.InstanceId // empty' <<<"$I")"
STATE="$(jq -r '.State.Name // empty' <<<"$I")"
PUBLIC_IP="$(jq -r '.PublicIpAddress // empty' <<<"$I")"

if [ "$n" -eq 0 ]; then
  no "1.3 launch an instance named amigos-web (EC2 → Launch instances)"
elif [ "$n" -gt 1 ]; then
  no "1.3 you have $n instances named amigos-web - terminate the extras (each one is billed)"
else
  type="$(jq -r '.InstanceType' <<<"$I")"
  ami="$(aws ec2 describe-images --image-ids "$(jq -r '.ImageId' <<<"$I")" --query 'Images[0].Name' --output text 2>/dev/null)"
  in_sg="$(jq -r --arg sg "$SG_ID" '[.SecurityGroups[]?.GroupId] | index($sg) != null' <<<"$I")"
  tag="$(jq -r --arg k "$TAG_KEY" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""' <<<"$I")"
  keyname="$(jq -r '.KeyName // ""' <<<"$I")"
  if [ "$STATE" != running ]; then
    no "1.3 amigos-web is $STATE - start it (Instance state → Start instance)"
  elif [[ "$FREE_TYPES" != *" $type "* ]]; then
    no "1.3 amigos-web is a $type - use t3.micro (Instance state → Stop, then Actions → Instance settings → Change instance type)"
  elif [ -n "$ami" ] && [ "$ami" != None ] && { [[ "$ami" != al2023-ami-* ]] || [[ "$ami" == al2023-ami-minimal* ]]; }; then
    no "1.3 amigos-web runs $ami - launch it again from Amazon Linux 2023 (the standard AMI, not minimal)"
  elif [ -z "$SG_ID" ] || [ "$in_sg" != true ]; then
    no "1.3 amigos-web is not in web-sg (Actions → Security → Change security groups)"
  elif [ "$keyname" != amigos-key ]; then
    no "1.3 amigos-web was launched with key pair '${keyname:-none}', not amigos-key - a key can't be added later: terminate it and launch again"
  elif [ "$tag" != "$TAG_VALUE" ]; then
    no "1.3 tag amigos-web with course = aws-essentials (Tags tab → Manage tags)"
  else
    ok "1.3 instance 'amigos-web' is running ($type, Amazon Linux 2023, web-sg, amigos-key)"
  fi
fi

echo "Tier 2 - SSH in, run nginx in Docker"

# One look inside the server, over SSH. The probe prints lines like:
#   connected=yes  active=active  enabled=enabled
#   web=running|nginx:alpine|unless-stopped|80/tcp=80 |/srv/www:/usr/share/nginx/html
#   fp=SHA256:...   (one per key that has logged in as ec2-user)
PROBE='echo connected=yes
echo "active=$(systemctl is-active docker 2>/dev/null)"
echo "enabled=$(systemctl is-enabled docker 2>/dev/null)"
command -v docker >/dev/null && echo "web=$(docker inspect web --format "{{.State.Status}}|{{.Config.Image}}|{{.HostConfig.RestartPolicy.Name}}|{{range \$p, \$b := .HostConfig.PortBindings}}{{\$p}}={{(index \$b 0).HostPort}} {{end}}|{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}" 2>/dev/null)"
journalctl -u sshd --no-pager -o cat 2>/dev/null | grep "Accepted publickey for ec2-user" | grep -o "SHA256:[A-Za-z0-9+/]*" | sort -u | sed "s/^/fp=/"
true'
inside="" ssh_err=""
if [ "$STATE" = running ] && [ -n "$PUBLIC_IP" ]; then
  rm -f /tmp/probe /tmp/probe.pub
  ssh-keygen -q -t ed25519 -N '' -C aws-essentials-checker -f /tmp/probe >/dev/null 2>&1
  if aws ec2-instance-connect send-ssh-public-key --instance-id "$IID" --instance-os-user ec2-user \
       --ssh-public-key file:///tmp/probe.pub >/dev/null 2>/tmp/eic-err; then
    inside="$(ssh -i /tmp/probe -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
      "ec2-user@$PUBLIC_IP" 'sudo bash -s' <<<"$PROBE" 2>/tmp/ssh-err)"
    ssh_err="$(tr '\n' ' ' </tmp/ssh-err)"
  else
    ssh_err="instance connect: $(tr '\n' ' ' </tmp/eic-err)"
  fi
fi
field() { sed -n "s/^$1=//p" <<<"$inside" | head -1; }
d_active="$(field active)"; d_enabled="$(field enabled)"
IFS='|' read -r c_state c_image c_restart c_ports c_mounts <<<"$(field web)"

if [ "$STATE" != running ]; then
  no "2.1 you logged in to amigos-web over SSH - it must be running (1.3)"
elif [ -z "$PUBLIC_IP" ]; then
  no "2.1 amigos-web has no public IP - launch it again with Auto-assign public IP: Enable"
elif [ "$(field connected)" != yes ]; then
  case "$ssh_err" in
    *"timed out"*|*"Connection refused"*|*"No route"*)
      no "2.1 SSH to $PUBLIC_IP times out from this machine - web-sg's SSH rule must allow ${MY_IP:-your IP}/32 (your IP changes now and then)" ;;
    *)
      no "2.1 the checker could not log in to amigos-web over SSH: ${ssh_err:-no answer} - try again in a minute" ;;
  esac
elif [ -z "$KEY_FP" ]; then
  no "2.1 create the key pair amigos-key first (1.2)"
elif grep -qx "fp=$KEY_FP" <<<"$inside"; then
  ok "2.1 you logged in to amigos-web over SSH with amigos-key"
else
  no "2.1 no SSH login with amigos-key on amigos-web yet - set up ~/.ssh/config (2.1) and run: ssh amigos-web"
fi

if [ "$(field connected)" != yes ]; then
  no "2.2 Docker is installed, running and starts at boot - the checker needs SSH to amigos-web first (2.1)"
elif ! grep -q '^web=' <<<"$inside" && [ -z "$d_enabled" ]; then
  no "2.2 install Docker on the server: sudo dnf install -y docker"
elif [ "$d_active" != active ]; then
  no "2.2 Docker is installed but not running: sudo systemctl enable --now docker"
elif [ "$d_enabled" != enabled ]; then
  no "2.2 Docker is running but won't start after a reboot: sudo systemctl enable docker"
else
  ok "2.2 Docker is installed, running and starts at boot"
fi

if [ "$d_active" != active ]; then
  no "2.3 nginx runs in a container named 'web' - get Docker running first (2.2)"
elif [ -z "$c_state" ]; then
  no "2.3 no container named 'web' - run it with the docker run command in 2.3"
elif [ "$c_state" != running ]; then
  no "2.3 the container 'web' is $c_state - sudo docker start web (sudo docker logs web shows why it stopped)"
elif [[ "$c_image" != nginx* ]]; then
  no "2.3 the container 'web' runs $c_image - it should run nginx:alpine"
elif [[ "$c_ports" != *"80/tcp=80 "* ]]; then
  no "2.3 the container 'web' doesn't publish port 80 - recreate it with -p 80:80 (sudo docker rm -f web, then run it again)"
elif [[ "$c_mounts" != *"/srv/www:/usr/share/nginx/html"* ]]; then
  no "2.3 the container 'web' doesn't mount your site - recreate it with -v /srv/www:/usr/share/nginx/html:ro"
elif [ "$c_restart" != unless-stopped ] && [ "$c_restart" != always ]; then
  no "2.3 the container 'web' won't come back after a reboot - recreate it with --restart unless-stopped"
else
  page "http://$PUBLIC_IP/"
  if [ "$CODE" = 200 ] && grep -q 'amigos-web' /tmp/page; then
    ok "2.3 nginx runs in a container named 'web' and serves http://$PUBLIC_IP"
  elif [ "$CODE" = 200 ]; then
    no "2.3 http://$PUBLIC_IP shows a page, but not yours - is /srv/www empty? user-data.sh must be pasted at launch"
  else
    explain_no_answer 2.3 "$PUBLIC_IP"
  fi
fi

echo "Tier 3 - A fixed address"

eip="$(aws ec2 describe-addresses --output json 2>/dev/null)"
[ -n "$eip" ] || eip='{}'
if [ -z "$IID" ]; then
  no "3.1 an Elastic IP is attached to amigos-web - launch amigos-web first (1.3)"
else
  mine="$(jq -c --arg i "$IID" '[.Addresses[]? | select(.InstanceId == $i)][0] // {}' <<<"$eip")"
  EIP="$(jq -r '.PublicIp // empty' <<<"$mine")"
  eip_tag="$(jq -r --arg k "$TAG_KEY" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""' <<<"$mine")"
  if [ -z "$EIP" ]; then
    no "3.1 allocate an Elastic IP and associate it with amigos-web (EC2 → Elastic IPs)"
  elif [ "$eip_tag" != "$TAG_VALUE" ]; then
    no "3.1 tag the Elastic IP $EIP with course = aws-essentials"
  elif [ "$STATE" != running ]; then
    no "3.1 the Elastic IP $EIP is attached, but amigos-web is $STATE"
  else
    page "http://$EIP/"
    if [ "$CODE" = 200 ] && grep -q 'amigos-web' /tmp/page; then
      ok "3.1 the Elastic IP $EIP is attached to amigos-web and serves the page"
      note "put it in ~/.ssh/config:  Host amigos-web  →  HostName $EIP"
    else
      explain_no_answer 3.1 "$EIP"
    fi
  fi
fi

score
[[ $fail -eq 0 ]] && echo "🎉 A server only you can log in to, one ssh away, running nginx in Docker - at an address that stays put."

# ---- what is billing right now --------------------------------------------------
running="$(jq -r '[.[] | select(.State.Name == "running" or .State.Name == "pending") | .InstanceId] | join(" ")' <<<"$inst")"
stopped="$(jq -r '[.[] | select(.State.Name == "stopped" or .State.Name == "stopping") | .InstanceId] | join(" ")' <<<"$inst")"
ips="$(jq -r '[.Addresses[]? | .PublicIp] | join(" ")' <<<"$eip")"
idle="$(jq -r '[.Addresses[]? | select(.AssociationId == null) | .PublicIp] | join(" ")' <<<"$eip")"
if [ -n "$running$stopped$ips" ]; then
  echo
  echo "⚠️  Billed by the hour in us-east-1 right now:"
  [ -n "$running" ] && echo "   - running amigos-web: $running  (server + public IP, about \$0.015/hour)"
  [ -n "$stopped" ] && echo "   - stopped amigos-web: $stopped  (no server charge, but its disk still is)"
  [ -n "$ips" ]     && echo "   - Elastic IPs: $ips  (\$0.005/hour each)"
  [ -n "$idle" ]    && echo "     not attached to anything: $idle - release it if you don't need it"
  echo "   When you are done: ${LAUNCHER:-./course.sh} stop 02-ec2"
fi
exit 0
