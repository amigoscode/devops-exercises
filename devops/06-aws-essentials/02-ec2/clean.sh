#!/usr/bin/env bash
# Deletes what "02 - EC2" created, so nothing is left billing:
#   - every instance named amigos-web (terminated - its disk goes with it)
#   - Elastic IPs tagged course=aws-essentials or attached to amigos-web (released)
#   - the security group web-sg
# Always kept: the default VPC, and your key pair amigos-key -
# it is the course's SSH key, every later section's servers use it (and it is free).
#
# Runs inside the AWS CLI container, after lib/aws.sh (which has the delete_* helpers).

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }

echo "Deleting what section 02 created:"

iids="$(ids ec2 describe-instances --filters Name=tag:Name,Values=amigos-web \
  Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].InstanceId')"

# Elastic IPs first: released before the instance goes, so none is left idle.
eips="$(aws ec2 describe-addresses --output json 2>/dev/null)"
[ -n "$eips" ] || eips='{}'
jq -r --arg k "$TAG_KEY" --arg v "$TAG_VALUE" --arg ids " $(echo $iids) " '
  .Addresses[]? | select(([.Tags[]? | select(.Key == $k and .Value == $v)] | length > 0)
                         or (.InstanceId != null and ($ids | contains(" " + .InstanceId + " "))))
  | [.AllocationId, (.AssociationId // "-"), .PublicIp] | @tsv' <<<"$eips" |
while IFS=$'\t' read -r alloc assoc ip; do
  [ "$assoc" != - ] && aws ec2 disassociate-address --association-id "$assoc"
  aws ec2 release-address --allocation-id "$alloc" && echo "  released Elastic IP $ip"
done

if [ -n "$iids" ]; then
  # shellcheck disable=SC2086
  aws ec2 terminate-instances --instance-ids $iids >/dev/null &&
    echo "  terminating $(echo $iids) (waiting for it to finish, about a minute)..."
  # shellcheck disable=SC2086
  aws ec2 wait instance-terminated --instance-ids $iids && echo "  terminated $(echo $iids)"
fi

for sg in $(ids ec2 describe-security-groups --filters Name=group-name,Values=web-sg --query 'SecurityGroups[].GroupId'); do
  aws ec2 delete-security-group --group-id "$sg" >/dev/null && echo "  deleted security group web-sg ($sg)"
done

aws ec2 describe-key-pairs --key-names amigos-key >/dev/null 2>&1 &&
  echo "  kept key pair amigos-key (the course's SSH key - later sections use it)"
echo "Done. Nothing from this section is billing any more."
