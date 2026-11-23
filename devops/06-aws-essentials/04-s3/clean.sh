#!/usr/bin/env bash
# Deletes what "04 - S3" created:
#   - the server amigos-reader (terminated) and its security group reader-sg
#   - the role ec2-s3-reader and its instance profile
#   - both buckets, with every file, old version and delete marker in them
# The S3ReadOnlyCourse policy is deleted only if this section's setup created it (tag
# seeded-by=04-s3) - if you built it in section 03 it stays, narrowed or not. Always
# kept: the default VPC and your key pair amigos-key.
#
# Runs inside the AWS CLI container, after lib/aws.sh (which has the delete_* helpers).

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }
POLICY_ARN="arn:aws:iam::$ACCOUNT:policy/S3ReadOnlyCourse"

echo "Deleting what section 04 created:"

inst="$(aws ec2 describe-instances --filters Name=tag:Name,Values=amigos-reader \
  Name=instance-state-name,Values=pending,running,stopping,stopped --output json 2>/dev/null)"
[ -n "$inst" ] || inst='{}'
iids="$(jq -r '[.Reservations[]?.Instances[]?.InstanceId] | join(" ")' <<<"$inst")"
# The security groups to delete afterwards: reader-sg, plus any launch-wizard-N group
# the launch wizard made for amigos-reader. Never the default group or web-sg.
sgs="$(jq -r '[.Reservations[]?.Instances[]?.SecurityGroups[]? | select(.GroupName | test("^(reader-sg|launch-wizard-[0-9]+)$")) | .GroupId] | unique | join(" ")' <<<"$inst")"
sgs="$sgs $(ids ec2 describe-security-groups --filters Name=group-name,Values=reader-sg --query 'SecurityGroups[].GroupId' | tr '\n' ' ')"

if [ -n "$iids" ]; then
  # shellcheck disable=SC2086
  aws ec2 terminate-instances --instance-ids $iids >/dev/null &&
    echo "  terminating $iids (waiting for it to finish, about a minute)..."
  # shellcheck disable=SC2086
  aws ec2 wait instance-terminated --instance-ids $iids && echo "  terminated $iids"
fi
for sg in $(tr ' ' '\n' <<<"$sgs" | sort -u); do
  aws ec2 delete-security-group --group-id "$sg" >/dev/null && echo "  deleted security group $sg"
done

delete_role ec2-s3-reader
delete_bucket "amigos-files-$ACCOUNT"
delete_bucket "amigos-site-$ACCOUNT"

if seeded_policy "$POLICY_ARN" 04-s3; then
  delete_policy "$POLICY_ARN"
elif aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  echo "  kept policy S3ReadOnlyCourse (you built it in section 03)"
fi
echo "Done. Nothing from this section is billing any more."
