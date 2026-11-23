#!/usr/bin/env bash
# Deletes what "06 - VPC" created, so nothing is left billing. The whole VPC named
# amigos-vpc is this section's, so everything inside it goes, in the order AWS needs:
#   - every server in it (amigos-bastion, amigos-app, anything else you launched there)
#   - its NAT gateways, and the Elastic IPs they used (released)
#   - its security groups, VPC endpoints, internet gateway, subnets, route tables and
#     network ACLs - then the VPC itself
# Never touched: the default VPC, anything outside amigos-vpc, your key pair amigos-key.
#
# Runs inside the AWS CLI container, after lib/aws.sh.

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }

echo "Deleting what section 06 created:"

# Tries a command a few times: AWS frees a VPC's parts a little after they are deleted
# (a server's network card, a NAT gateway's IP), so the next step can fail for a moment.
retry() { local i; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do "$@" 2>/tmp/retry-err && return 0; sleep 5; done; cat /tmp/retry-err >&2; return 1; }

vpcs="$(ids ec2 describe-vpcs --filters Name=tag:Name,Values=amigos-vpc Name=is-default,Values=false --query 'Vpcs[].VpcId')"
[ -n "$vpcs" ] || echo "  no VPC named amigos-vpc - nothing to delete"

for vpc in $vpcs; do
  iids="$(ids ec2 describe-instances --filters "Name=vpc-id,Values=$vpc" \
    Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].InstanceId' | tr '\n' ' ')"
  if [ -n "${iids// /}" ]; then
    # shellcheck disable=SC2086
    aws ec2 terminate-instances --instance-ids $iids >/dev/null &&
      echo "  terminating $iids(waiting for them to finish, about a minute)..."
    # shellcheck disable=SC2086
    aws ec2 wait instance-terminated --instance-ids $iids && echo "  terminated $iids"
  fi

  nats="$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc" Name=state,Values=pending,available,deleting,failed --output json 2>/dev/null)"
  [ -n "$nats" ] || nats='{}'
  eips="$(jq -r '[.NatGateways[]?.NatGatewayAddresses[]?.AllocationId // empty] | join(" ")' <<<"$nats")"
  natids="$(jq -r '[.NatGateways[]?.NatGatewayId] | join(" ")' <<<"$nats")"
  for n in $(jq -r '.NatGateways[]? | select(.State != "deleting") | .NatGatewayId' <<<"$nats"); do
    aws ec2 delete-nat-gateway --nat-gateway-id "$n" >/dev/null && echo "  deleting NAT gateway $n (about a minute)..."
  done
  if [ -n "$natids" ]; then
    # shellcheck disable=SC2086
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids $natids && echo "  deleted NAT gateway $natids"
  fi
  for a in $eips; do
    ip="$(aws ec2 describe-addresses --allocation-ids "$a" --query 'Addresses[0].PublicIp' --output text 2>/dev/null)" || continue
    retry aws ec2 release-address --allocation-id "$a" && echo "  released Elastic IP $ip (it was the NAT gateway's)"
  done

  for e in $(ids ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc" --query 'VpcEndpoints[].VpcEndpointId'); do
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$e" >/dev/null && echo "  deleted VPC endpoint $e"
  done

  # Security groups can point at each other (app-sg allows bastion-sg), so empty
  # every group's rules first, then delete them.
  sgs="$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" --output json 2>/dev/null)"
  [ -n "$sgs" ] || sgs='{}'
  for g in $(jq -r '.SecurityGroups[]? | select(.GroupName != "default") | .GroupId' <<<"$sgs"); do
    perms="$(jq -c --arg g "$g" '.SecurityGroups[] | select(.GroupId == $g) | .IpPermissions' <<<"$sgs")"
    [ "$perms" != "[]" ] && aws ec2 revoke-security-group-ingress --group-id "$g" --ip-permissions "$perms" >/dev/null 2>&1
  done
  for g in $(jq -r '.SecurityGroups[]? | select(.GroupName != "default") | "\(.GroupId)=\(.GroupName)"' <<<"$sgs"); do
    retry aws ec2 delete-security-group --group-id "${g%%=*}" && echo "  deleted security group ${g#*=} (${g%%=*})"
  done

  for igw in $(ids ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId'); do
    retry aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" &&
      aws ec2 delete-internet-gateway --internet-gateway-id "$igw" && echo "  deleted internet gateway $igw"
  done

  for s in $(ids ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId'); do
    name="$(aws ec2 describe-subnets --subnet-ids "$s" --query "Subnets[0].Tags[?Key=='Name'].Value | [0]" --output text 2>/dev/null)"
    retry aws ec2 delete-subnet --subnet-id "$s" && echo "  deleted subnet ${name:-$s} ($s)"
  done

  # The main route table and the default network ACL go with the VPC itself.
  for rt in $(ids ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?!(Associations[?Main])].RouteTableId'); do
    aws ec2 delete-route-table --route-table-id "$rt" && echo "  deleted route table $rt"
  done
  for acl in $(ids ec2 describe-network-acls --filters "Name=vpc-id,Values=$vpc" Name=default,Values=false --query 'NetworkAcls[].NetworkAclId'); do
    aws ec2 delete-network-acl --network-acl-id "$acl" && echo "  deleted network ACL $acl"
  done

  retry aws ec2 delete-vpc --vpc-id "$vpc" && echo "  deleted VPC amigos-vpc ($vpc)"
done

# An internet gateway named amigos-igw that never got attached.
for igw in $(ids ec2 describe-internet-gateways --filters Name=tag:Name,Values=amigos-igw --query 'InternetGateways[?length(Attachments)==`0`].InternetGatewayId'); do
  aws ec2 delete-internet-gateway --internet-gateway-id "$igw" && echo "  deleted internet gateway amigos-igw ($igw)"
done

loose="$(aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].PublicIp' --output text 2>/dev/null | tr '\t' ' ')"
if [ -n "$loose" ] && [ "$loose" != None ]; then
  echo "  ⚠️  Elastic IPs attached to nothing are still billing: $loose"
  echo "     If one was your NAT gateway's, release it: EC2 → Elastic IPs → Actions → Release"
fi
aws ec2 describe-key-pairs --key-names amigos-key >/dev/null 2>&1 &&
  echo "  kept key pair amigos-key (the course's SSH key - later sections use it)"
echo "Done. Nothing from this section is billing any more."
