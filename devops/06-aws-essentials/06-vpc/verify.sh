#!/usr/bin/env bash
# Grades "06 - VPC" against the student's real AWS account.
#
# Runs inside the AWS checker container, after lib/aws.sh. It reads the VPC service
# (your VPC, subnets, internet gateway, route tables, NAT gateway) and EC2 (both
# servers and their security groups). To look inside amigos-app, which has no public
# IP, it logs in the way you do: over SSH through amigos-bastion, with a throwaway
# key handed to both servers through EC2 Instance Connect - never your amigos-key.
# On amigos-app it only reads who has logged in, and asks checkip.amazonaws.com
# which IP the internet sees. Nothing is changed. At the end it lists what is still
# billing.

require_login \
  "1.1 VPC 'amigos-vpc' with CIDR 10.0.0.0/16" \
  "1.2 subnets public-a, public-b, private-a, private-b" \
  "1.3 internet gateway 'amigos-igw' is attached to amigos-vpc" \
  "1.4 route tables public-rt and private-rt" \
  "1.5 public subnets give servers a public IP, private ones don't" \
  "2.1 'amigos-bastion' is running in a public subnet" \
  "2.2 'amigos-app' is running in a private subnet, SSH only from bastion-sg" \
  "2.3 you logged in to amigos-app through the bastion, with amigos-key" \
  "3.1 NAT gateway 'amigos-nat' is available in a public subnet" \
  "3.2 private-rt sends 0.0.0.0/0 to amigos-nat" \
  "3.3 amigos-app reaches the internet through amigos-nat"

FREE_TYPES=" t3.micro t3.small t4g.micro t4g.small t2.micro "
MY_IP="$(curl -s -m 5 https://checkip.amazonaws.com 2>/dev/null | tr -d '[:space:]')"

tag_of() { jq -r --arg k "$1" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""'; }
json() { local j; j="$(aws "$@" --output json 2>/dev/null)"; [ -n "$j" ] && echo "$j" || echo '{}'; }

# The subnets this section asks for: name, CIDR, zone.
SUBNETS="public-a 10.0.1.0/24 us-east-1a
public-b 10.0.2.0/24 us-east-1b
private-a 10.0.11.0/24 us-east-1a
private-b 10.0.12.0/24 us-east-1b"

echo "Tier 1 - Your own network"

vpcs="$(json ec2 describe-vpcs --filters Name=tag:Name,Values=amigos-vpc)"
nvpc="$(jq '.Vpcs | length' <<<"$vpcs")"
V="$(jq -c '.Vpcs[0] // {}' <<<"$vpcs")"
VPC="$(jq -r '.VpcId // empty' <<<"$V")"
CIDR="$(jq -r '.CidrBlock // empty' <<<"$V")"

if [ "$nvpc" -eq 0 ]; then
  VPC=""
  no "1.1 create a VPC named amigos-vpc (VPC → Your VPCs → Create VPC → VPC only, IPv4 CIDR 10.0.0.0/16)"
elif [ "$nvpc" -gt 1 ]; then
  no "1.1 you have $nvpc VPCs named amigos-vpc - delete the extras (Your VPCs → Actions → Delete VPC)"
  VPC=""
elif [ "$CIDR" != 10.0.0.0/16 ]; then
  no "1.1 amigos-vpc has CIDR $CIDR - a VPC's CIDR can't be changed: delete it and create it again with 10.0.0.0/16"
elif [ "$(tag_of "$TAG_KEY" <<<"$V")" != "$TAG_VALUE" ]; then
  no "1.1 tag amigos-vpc with course = aws-essentials (Your VPCs → amigos-vpc → Tags)"
else
  ok "1.1 VPC 'amigos-vpc' ($VPC, $CIDR)"
fi

# Everything below lives inside amigos-vpc.
if [ -n "$VPC" ]; then
  subnets="$(json ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC")"
  rts="$(json ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC")"
  igws="$(json ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC")"
else
  subnets='{}' rts='{}' igws='{}'
fi
subnet_id() { jq -r --arg n "$1" '[.Subnets[]? | select(([.Tags[]? | select(.Key == "Name") | .Value][0] // "") == $n) | .SubnetId][0] // ""' <<<"$subnets"; }
subnet_name() { jq -r --arg s "$1" '[.Subnets[]? | select(.SubnetId == $s) | ([.Tags[]? | select(.Key == "Name") | .Value][0] // .SubnetId)][0] // $s' <<<"$subnets"; }
# The route table a subnet really uses: its own association, or else the VPC's main one.
rt_of() { jq -r --arg s "$1" '(.RouteTables // []) as $r
  | ([$r[] | select(any(.Associations[]?; .SubnetId == $s)) | .RouteTableId][0]
     // [$r[] | select(any(.Associations[]?; .Main == true)) | .RouteTableId][0] // "")' <<<"$rts"; }
rt_named() { jq -r --arg n "$1" '[.RouteTables[]? | select(([.Tags[]? | select(.Key == "Name") | .Value][0] // "") == $n) | .RouteTableId][0] // ""' <<<"$rts"; }
# What a route table's 0.0.0.0/0 route points at (igw-..., nat-..., or nothing), and its state.
default_route() { jq -r --arg t "$1" '[.RouteTables[]? | select(.RouteTableId == $t) | .Routes[]?
  | select(.DestinationCidrBlock == "0.0.0.0/0") | "\(.GatewayId // .NatGatewayId // .NetworkInterfaceId // "other") \(.State)"][0] // ""' <<<"$rts"; }
# A subnet is public when the route table it uses sends 0.0.0.0/0 to an internet gateway.
is_public() { local r; r="$(default_route "$(rt_of "$1")")"; [[ "$r" == "igw-"*" active" ]]; }

declare -A SUB
problem=""
while read -r name cidr az; do
  id="$(subnet_id "$name")"
  SUB[$name]="$id"
  [ -n "$problem" ] && continue
  if [ -z "$id" ]; then
    other="$(jq -r --arg c "$cidr" '[.Subnets[]? | select(.CidrBlock == $c) | ([.Tags[]? | select(.Key == "Name") | .Value][0] // .SubnetId)][0] // ""' <<<"$subnets")"
    if [ -n "$other" ]; then problem="the subnet $cidr is named '$other' - rename it $name (Subnets → select it → Tags → Name)"
    else problem="create subnet $name in amigos-vpc: zone $az, CIDR $cidr (Subnets → Create subnet)"; fi
  else
    got_cidr="$(jq -r --arg s "$id" '.Subnets[] | select(.SubnetId == $s) | .CidrBlock' <<<"$subnets")"
    got_az="$(jq -r --arg s "$id" '.Subnets[] | select(.SubnetId == $s) | .AvailabilityZone' <<<"$subnets")"
    if [ "$got_cidr" != "$cidr" ]; then problem="$name is $got_cidr, not $cidr - a subnet's CIDR can't be changed: delete it and create it again"
    elif [ "$got_az" != "$az" ]; then problem="$name is in $got_az, not $az - a subnet can't move zones: delete it and create it again in $az"
    fi
  fi
done <<<"$SUBNETS"
if [ -z "$VPC" ]; then
  no "1.2 subnets public-a, public-b, private-a, private-b - create amigos-vpc first (1.1)"
elif [ -n "$problem" ]; then
  no "1.2 $problem"
else
  ok "1.2 four subnets: public-a and private-a in us-east-1a, public-b and private-b in us-east-1b"
fi

IGW="$(jq -r '.InternetGateways[0].InternetGatewayId // empty' <<<"$igws")"
igw_name="$(jq -c '.InternetGateways[0] // {}' <<<"$igws" | tag_of Name)"
if [ -z "$VPC" ]; then
  no "1.3 internet gateway amigos-igw - create amigos-vpc first (1.1)"
elif [ -z "$IGW" ]; then
  loose="$(aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=amigos-igw --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)"
  if [ -n "$loose" ] && [ "$loose" != None ]; then
    no "1.3 amigos-igw is not attached to amigos-vpc (Internet gateways → amigos-igw → Actions → Attach to VPC)"
  else
    no "1.3 create an internet gateway named amigos-igw and attach it to amigos-vpc (VPC → Internet gateways)"
  fi
elif [ "$igw_name" != amigos-igw ]; then
  no "1.3 amigos-vpc's internet gateway $IGW is named '${igw_name:-nothing}' - name it amigos-igw"
else
  ok "1.3 internet gateway 'amigos-igw' ($IGW) is attached to amigos-vpc"
fi

PUB_RT="$(rt_named public-rt)"
PRIV_RT="$(rt_named private-rt)"
pub_route="$(default_route "$PUB_RT")"
priv_route="$(default_route "$PRIV_RT")"
if [ -z "$VPC" ]; then
  no "1.4 route tables public-rt and private-rt - create amigos-vpc first (1.1)"
elif [ -z "$PUB_RT" ]; then
  no "1.4 create a route table named public-rt in amigos-vpc (VPC → Route tables → Create route table)"
elif [ -z "$IGW" ] || [ "$pub_route" != "$IGW active" ]; then
  no "1.4 public-rt needs the route 0.0.0.0/0 → Internet Gateway amigos-igw (public-rt → Routes → Edit routes)"
elif [ "$(rt_of "${SUB[public-a]}")" != "$PUB_RT" ] || [ "$(rt_of "${SUB[public-b]}")" != "$PUB_RT" ]; then
  no "1.4 associate public-a and public-b with public-rt (public-rt → Subnet associations → Edit subnet associations)"
elif [ -z "$PRIV_RT" ]; then
  no "1.4 create a route table named private-rt in amigos-vpc - with no route to the internet gateway"
elif [[ "$priv_route" == igw-* ]]; then
  no "1.4 private-rt sends 0.0.0.0/0 to the internet gateway - that makes the private subnets public: remove that route"
elif [ "$(rt_of "${SUB[private-a]}")" != "$PRIV_RT" ] || [ "$(rt_of "${SUB[private-b]}")" != "$PRIV_RT" ]; then
  no "1.4 associate private-a and private-b with private-rt (private-rt → Subnet associations → Edit subnet associations)"
else
  ok "1.4 public-rt sends 0.0.0.0/0 to amigos-igw for public-a and public-b; private-rt has no way to the internet gateway"
fi

maps() { jq -r --arg s "$1" '[.Subnets[]? | select(.SubnetId == $s) | .MapPublicIpOnLaunch][0] // false' <<<"$subnets"; }
if [ -z "$VPC" ] || [ -z "${SUB[public-a]}" ] || [ -z "${SUB[public-b]}" ]; then
  no "1.5 public subnets give servers a public IP - create the subnets first (1.2)"
elif [ "$(maps "${SUB[public-a]}")" != true ] || [ "$(maps "${SUB[public-b]}")" != true ]; then
  no "1.5 turn on Enable auto-assign public IPv4 address for public-a and public-b (Subnets → Actions → Edit subnet settings)"
elif { [ -n "${SUB[private-a]}" ] && [ "$(maps "${SUB[private-a]}")" = true ]; } ||
     { [ -n "${SUB[private-b]}" ] && [ "$(maps "${SUB[private-b]}")" = true ]; }; then
  no "1.5 a private subnet gives servers a public IP - turn auto-assign public IPv4 off for private-a and private-b"
else
  ok "1.5 public-a and public-b give servers a public IP; private-a and private-b don't"
fi

echo "Tier 2 - A bastion and a private server"

key="$(aws ec2 describe-key-pairs --key-names amigos-key --include-public-key --query 'KeyPairs[0].PublicKey' --output text 2>/dev/null)"
KEY_FP=""
[ -n "$key" ] && [ "$key" != None ] && KEY_FP="$(ssh-keygen -lf /dev/stdin <<<"$key" 2>/dev/null | awk '{print $2}')"

sg_named() { [ -n "$VPC" ] && aws ec2 describe-security-groups --filters "Name=group-name,Values=$1" "Name=vpc-id,Values=$VPC" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null | grep -v None; }
BASTION_SG="$(sg_named bastion-sg)"
APP_SG="$(sg_named app-sg)"
# The SSH rules of a group, one per line: "cidr 1.2.3.4/32", "cidr6 ::/0" or "sg sg-0abc".
ssh_sources() { [ -n "$1" ] && aws ec2 describe-security-groups --group-ids "$1" --output json 2>/dev/null | jq -r '
  .SecurityGroups[0].IpPermissions[]? | select(.IpProtocol == "-1" or (.IpProtocol == "tcp" and .FromPort <= 22 and .ToPort >= 22))
  | ((.IpRanges[]? | "cidr \(.CidrIp)"), (.Ipv6Ranges[]? | "cidr6 \(.CidrIpv6)"), (.UserIdGroupPairs[]? | "sg \(.GroupId)"), (.PrefixListIds[]? | "pl \(.PrefixListId)"))'; }

# Checks a server against what every section asks: running, free type, Amazon Linux
# 2023, amigos-key, the course tag, inside amigos-vpc. Prints the problem, if any.
#   server_problem <task> <name> <instance-json>
server_problem() {
  local t="$1" nm="$2" I="$3" type ami keyname st
  st="$(jq -r '.State.Name' <<<"$I")"
  type="$(jq -r '.InstanceType' <<<"$I")"
  ami="$(aws ec2 describe-images --image-ids "$(jq -r '.ImageId' <<<"$I")" --query 'Images[0].Name' --output text 2>/dev/null)"
  keyname="$(jq -r '.KeyName // ""' <<<"$I")"
  if [ "$st" != running ]; then echo "$nm is $st - start it (Instance state → Start instance)"
  elif [ "$(jq -r '.VpcId // ""' <<<"$I")" != "$VPC" ]; then
    echo "$nm is not in amigos-vpc - terminate it and launch it again: Network settings → Edit → VPC amigos-vpc"
  elif [[ "$FREE_TYPES" != *" $type "* ]]; then echo "$nm is a $type - use t3.micro"
  elif [ -n "$ami" ] && [ "$ami" != None ] && { [[ "$ami" != al2023-ami-* ]] || [[ "$ami" == al2023-ami-minimal* ]]; }; then
    echo "$nm runs $ami - launch it again from Amazon Linux 2023 (the standard AMI)"
  elif [ "$keyname" != amigos-key ]; then
    echo "$nm was launched with key pair '${keyname:-none}', not amigos-key - terminate it and launch again"
  elif [ "$(tag_of "$TAG_KEY" <<<"$I")" != "$TAG_VALUE" ]; then
    echo "tag $nm with course = aws-essentials (Tags tab → Manage tags)"
  fi
}
in_sg() { jq -e --arg g "$2" '[.SecurityGroups[]?.GroupId] | index($g) != null' <<<"$1" >/dev/null 2>&1; }

bastions="$(instances_named amigos-bastion)"
nb="$(jq length <<<"$bastions")"
B="$(jq -c '.[0] // {}' <<<"$bastions")"
BID="$(jq -r '.InstanceId // empty' <<<"$B")"
BST="$(jq -r '.State.Name // empty' <<<"$B")"
BIP="$(jq -r '.PublicIpAddress // empty' <<<"$B")"
BSUB="$(jq -r '.SubnetId // empty' <<<"$B")"
b_src="$(ssh_sources "$BASTION_SG")"

if [ "$nb" -eq 0 ]; then
  no "2.1 launch an instance named amigos-bastion in public-a (EC2 → Launch instances)"
elif [ "$nb" -gt 1 ]; then
  no "2.1 you have $nb instances named amigos-bastion - terminate the extras (each one is billed)"
elif p="$(server_problem 2.1 amigos-bastion "$B")"; [ -n "$p" ]; then
  no "2.1 $p"
elif ! is_public "$BSUB"; then
  no "2.1 amigos-bastion is in $(subnet_name "$BSUB"), which has no route to the internet gateway - terminate it and launch it in public-a"
elif [ -z "$BIP" ]; then
  no "2.1 amigos-bastion has no public IP - launch it again with Auto-assign public IP: Enable (or fix 1.5 first)"
elif [ -z "$BASTION_SG" ]; then
  no "2.1 create the security group bastion-sg in amigos-vpc: SSH from My IP (EC2 → Security Groups)"
elif ! in_sg "$B" "$BASTION_SG"; then
  no "2.1 amigos-bastion is not in bastion-sg (Actions → Security → Change security groups)"
elif grep -qE '^cidr6? (0\.0\.0\.0/0|::/0)$' <<<"$b_src"; then
  no "2.1 bastion-sg has SSH open to the whole internet - change the source to My IP (${MY_IP:-your IP}/32)"
elif [ -z "$b_src" ]; then
  no "2.1 bastion-sg has no SSH rule - add one: Type SSH, Source My IP"
else
  ok "2.1 'amigos-bastion' is running in $(subnet_name "$BSUB") at $BIP, SSH from your IP only"
fi

apps="$(instances_named amigos-app)"
na="$(jq length <<<"$apps")"
A="$(jq -c '.[0] // {}' <<<"$apps")"
AID="$(jq -r '.InstanceId // empty' <<<"$A")"
AST="$(jq -r '.State.Name // empty' <<<"$A")"
AIP="$(jq -r '.PrivateIpAddress // empty' <<<"$A")"
ASUB="$(jq -r '.SubnetId // empty' <<<"$A")"
a_src="$(ssh_sources "$APP_SG")"

if [ "$na" -eq 0 ]; then
  no "2.2 launch an instance named amigos-app in private-a (EC2 → Launch instances)"
elif [ "$na" -gt 1 ]; then
  no "2.2 you have $na instances named amigos-app - terminate the extras (each one is billed)"
elif p="$(server_problem 2.2 amigos-app "$A")"; [ -n "$p" ]; then
  no "2.2 $p"
elif [ "$ASUB" != "${SUB[private-a]}" ] && [ "$ASUB" != "${SUB[private-b]}" ]; then
  no "2.2 amigos-app is in $(subnet_name "$ASUB") - terminate it and launch it in private-a"
elif [ -n "$(jq -r '.PublicIpAddress // empty' <<<"$A")" ]; then
  no "2.2 amigos-app has a public IP - a private server must not: terminate it and launch it again with Auto-assign public IP: Disable"
elif [ -z "$APP_SG" ]; then
  no "2.2 create the security group app-sg in amigos-vpc: SSH from the security group bastion-sg"
elif ! in_sg "$A" "$APP_SG"; then
  no "2.2 amigos-app is not in app-sg (Actions → Security → Change security groups)"
elif cidr="$(grep -E '^cidr' <<<"$a_src" | head -1 | cut -d' ' -f2)"; [ -n "$cidr" ]; then
  no "2.2 app-sg allows SSH from $cidr - remove that rule and use the security group bastion-sg as the source, not an IP range"
elif ! grep -qx "sg $BASTION_SG" <<<"$a_src"; then
  no "2.2 app-sg needs an SSH rule whose source is the security group bastion-sg (Edit inbound rules → Source: Custom → bastion-sg)"
else
  ok "2.2 'amigos-app' is running in $(subnet_name "$ASUB") at $AIP, no public IP, SSH only from bastion-sg"
fi

# One look inside amigos-app, through the bastion. Prints connected=yes, one fp= line
# per key that has logged in as ec2-user, and the IP the internet sees (egress=, empty
# when amigos-app can't reach the internet).
PROBE='echo connected=yes
journalctl -u sshd --no-pager -o cat 2>/dev/null | grep "Accepted publickey for ec2-user" | grep -o "SHA256:[A-Za-z0-9+/]*" | sort -u | sed "s/^/fp=/"
echo "egress=$(curl -s -m 6 https://checkip.amazonaws.com 2>/dev/null | tr -d "[:space:]")"
true'
if [ "$BST" = running ] && [ -n "$BIP" ] && [ "$AST" = running ] && [ -n "$AIP" ]; then
  ssh_probe_via "$BID" "$BIP" "$AID" "$AIP" "$PROBE"
else
  PROBE_OUT="" PROBE_ERR=""
fi
CONNECTED="$(sed -n 's/^connected=//p' <<<"$PROBE_OUT")"
EGRESS="$(sed -n 's/^egress=//p' <<<"$PROBE_OUT")"
inside_hint() { # inside_hint <id>: why the checker can't reach amigos-app
  if [ "$BST" != running ] || [ -z "$BIP" ]; then no "$1 the checker reaches amigos-app through amigos-bastion - it must be running with a public IP (2.1)"
  elif [ "$AST" != running ]; then no "$1 the checker looks inside amigos-app over SSH - it must be running (2.2)"
  else case "$PROBE_ERR" in
    *"$BIP"*|*"UNKNOWN port 65535"*|*"kex_exchange_identification"*)
      no "$1 SSH to amigos-bastion ($BIP) fails from this machine - bastion-sg must allow SSH from ${MY_IP:-your IP}/32, and no network ACL rule may block it (2.5)" ;;
    *"open failed"*|*"timed out"*|*"Connection refused"*|*"No route"*)
      no "$1 the bastion can't reach amigos-app ($AIP) on port 22 - app-sg must allow SSH from the security group bastion-sg" ;;
    *) no "$1 the checker could not log in to amigos-app through the bastion: ${PROBE_ERR:-no answer} - try again in a minute" ;;
  esac; fi
}

if [ "$CONNECTED" != yes ]; then
  inside_hint 2.3
elif [ -z "$KEY_FP" ]; then
  no "2.3 there is no key pair amigos-key in us-east-1 - create it as in section 02 (task 1.2)"
elif grep -qx "fp=$KEY_FP" <<<"$PROBE_OUT"; then
  ok "2.3 you logged in to amigos-app through the bastion, with amigos-key"
else
  no "2.3 nobody has logged in to amigos-app with amigos-key yet - add Host amigos-app with ProxyJump amigos-bastion (see 2.3), then: ssh amigos-app"
fi

echo "Tier 3 - A way out: the NAT gateway"

if [ -n "$VPC" ]; then
  nats="$(json ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC" "Name=state,Values=pending,available,failed")"
else
  nats='{}'
fi
N="$(jq -c '(.NatGateways // []) | (map(select(([.Tags[]? | select(.Key == "Name") | .Value][0] // "") == "amigos-nat")) + .)[0] // {}' <<<"$nats")"
nn="$(jq '[.NatGateways[]? | select(.State != "failed")] | length' <<<"$nats")"
NAT="$(jq -r '.NatGatewayId // empty' <<<"$N")"
NST="$(jq -r '.State // empty' <<<"$N")"
NSUB="$(jq -r '.SubnetId // empty' <<<"$N")"
NMODE="$(jq -r '.AvailabilityMode // "zonal"' <<<"$N")"
NAT_IPS="$(jq -r '[.NatGatewayAddresses[]?.PublicIp // empty] | join(" ")' <<<"$N")"

if [ -z "$VPC" ]; then
  no "3.1 NAT gateway amigos-nat - create amigos-vpc first (1.1)"
elif [ -z "$NAT" ]; then
  no "3.1 create a NAT gateway named amigos-nat in public-a (VPC → NAT gateways → Create NAT gateway, Connectivity type Public, Allocate Elastic IP)"
elif [ "$(tag_of Name <<<"$N")" != amigos-nat ]; then
  no "3.1 amigos-vpc's NAT gateway $NAT is not named amigos-nat - name it (Tags → Name)"
elif [ "$NST" = pending ]; then
  no "3.1 amigos-nat is still pending - it takes a minute or two, check again soon"
elif [ "$NST" = failed ]; then
  no "3.1 amigos-nat failed ($(jq -r '.FailureMessage // "no reason given"' <<<"$N")) - delete it and create it again in public-a"
elif [ "$(jq -r '.ConnectivityType // "public"' <<<"$N")" != public ]; then
  no "3.1 amigos-nat is a private NAT gateway - it can't reach the internet: delete it and create one with Connectivity type Public"
elif [ "$NMODE" = zonal ] && ! is_public "$NSUB"; then
  no "3.1 amigos-nat is in $(subnet_name "$NSUB"), which has no route to the internet gateway - a NAT gateway must sit in a public subnet: delete it and create it in public-a"
elif [ -z "$NAT_IPS" ]; then
  no "3.1 amigos-nat has no public IP - delete it and create it again with Allocate Elastic IP"
else
  where="$( [ "$NMODE" = zonal ] && echo "in $(subnet_name "$NSUB")" || echo "(regional)")"
  ok "3.1 NAT gateway 'amigos-nat' ($NAT) is available $where, public IP $NAT_IPS"
  [ "${nn:-1}" -gt 1 ] && note "amigos-vpc has $nn NAT gateways - delete the extras, each one is billed by the hour"
fi

if [ -z "$PRIV_RT" ]; then
  no "3.2 private-rt sends 0.0.0.0/0 to amigos-nat - create private-rt first (1.4)"
elif [ -z "$NAT" ]; then
  no "3.2 private-rt sends 0.0.0.0/0 to amigos-nat - create the NAT gateway first (3.1)"
elif [ "$priv_route" = "$NAT blackhole" ] || [[ "$priv_route" == *" blackhole" ]]; then
  no "3.2 private-rt's 0.0.0.0/0 route is a blackhole - what it points at is gone: edit it to point at NAT Gateway amigos-nat"
elif [ "${priv_route%% *}" != "$NAT" ]; then
  no "3.2 add the route 0.0.0.0/0 → NAT Gateway amigos-nat to private-rt (private-rt → Routes → Edit routes)"
else
  ok "3.2 private-rt sends 0.0.0.0/0 to amigos-nat"
fi

if [ "$CONNECTED" != yes ]; then
  inside_hint 3.3
elif [ -z "$EGRESS" ]; then
  no "3.3 amigos-app still can't reach the internet - check 3.1 and 3.2, then on amigos-app: curl https://checkip.amazonaws.com"
elif [ -n "$NAT_IPS" ] && [[ " $NAT_IPS " == *" $EGRESS "* ]]; then
  ok "3.3 amigos-app reaches the internet, and the internet sees it as amigos-nat's IP $EGRESS"
else
  no "3.3 amigos-app reaches the internet as $EGRESS, not through amigos-nat (${NAT_IPS:-no NAT IP}) - check private-rt (3.2)"
fi

score
[[ $fail -eq 0 ]] && echo "🎉 Your own network: public and private subnets, a bastion to reach the private side, and a NAT gateway that lets it out - but nobody in."

# ---- what is billing right now --------------------------------------------------
running="$(jq -r -s '[.[][] | select(.State.Name == "running" or .State.Name == "pending") | (.Tags[]? | select(.Key == "Name") | .Value)] | join(" ")' <<<"$bastions $apps")"
live_nats="$(jq -r '[.NatGateways[]? | select(.State == "available" or .State == "pending") | ([.Tags[]? | select(.Key == "Name") | .Value][0] // .NatGatewayId)] | join(" ")' <<<"$nats")"
loose_eips="$(aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].PublicIp' --output text 2>/dev/null | tr '\t' ' ')"
[ "$loose_eips" = None ] && loose_eips=""
if [ -n "$running$live_nats$loose_eips" ]; then
  echo
  echo "⚠️  Still billing in us-east-1:"
  [ -n "$running" ] && echo "   - running servers: $running  (about \$0.015/hour each)"
  [ -n "$live_nats" ] && echo "   - NAT gateway: $live_nats  (\$0.045/hour + \$0.005/hour for its Elastic IP - about \$36 a month if you forget it)"
  [ -n "$loose_eips" ] && echo "   - Elastic IPs attached to nothing: $loose_eips  (\$0.005/hour each - release them: EC2 → Elastic IPs)"
  echo "   When you are done: ${LAUNCHER:-./course.sh} stop 06-vpc"
fi
exit 0
