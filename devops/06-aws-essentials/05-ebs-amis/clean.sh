#!/usr/bin/env bash
# Deletes what "05 - EBS and AMIs" created, so nothing is left billing:
#   - the servers amigos-data and amigos-clone (terminated)
#   - your image amigos-web-ami (deregistered) and the snapshots behind it
#   - the volumes data-vol and data-restore, and any other volume made from
#     data-snap or from the image's snapshots
#   - the snapshot data-snap
# The security group web-sg is deleted only if this section's setup created it (tag
# seeded-by=05-ebs-amis). Always kept: the default VPC and your key pair amigos-key.
#
# Runs inside the AWS CLI container, after lib/aws.sh (which has the delete_* helpers).

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }

echo "Deleting what section 05 created:"

# The image first: then nothing can launch from it while the rest goes.
imgs="$(aws ec2 describe-images --owners self --filters Name=name,Values=amigos-web-ami --output json 2>/dev/null)"
[ -n "$imgs" ] || imgs='{}'
ami_snaps="$(jq -r '[.Images[]?.BlockDeviceMappings[]?.Ebs.SnapshotId // empty] | join(" ")' <<<"$imgs")"
for ami in $(jq -r '.Images[]?.ImageId' <<<"$imgs"); do
  aws ec2 deregister-image --image-id "$ami" >/dev/null && echo "  deregistered image amigos-web-ami ($ami)"
done

iids="$(ids ec2 describe-instances --filters Name=tag:Name,Values=amigos-data,amigos-clone \
  Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].InstanceId' | tr '\n' ' ')"
if [ -n "${iids// /}" ]; then
  # shellcheck disable=SC2086
  aws ec2 terminate-instances --instance-ids $iids >/dev/null &&
    echo "  terminating $iids(waiting for them to finish, about a minute)..."
  # shellcheck disable=SC2086
  aws ec2 wait instance-terminated --instance-ids $iids && echo "  terminated $iids"
fi

data_snaps="$(ids ec2 describe-snapshots --owner-ids self --filters Name=tag:Name,Values=data-snap --query 'Snapshots[].SnapshotId' | tr '\n' ' ')"

# Volumes: by name, plus anything restored from this section's snapshots.
vols="$(ids ec2 describe-volumes --filters Name=tag:Name,Values=data-vol,data-restore --query 'Volumes[].VolumeId')"
for s in $data_snaps $ami_snaps; do
  vols="$vols $(ids ec2 describe-volumes --filters "Name=snapshot-id,Values=$s" --query 'Volumes[].VolumeId')"
done
for v in $(tr ' ' '\n' <<<"$vols" | grep . | sort -u); do
  st="$(aws ec2 describe-volumes --volume-ids "$v" --query 'Volumes[0].State' --output text 2>/dev/null)"
  if [ "$st" = in-use ]; then
    aws ec2 detach-volume --volume-id "$v" >/dev/null 2>&1
    aws ec2 wait volume-available --volume-ids "$v"
  fi
  aws ec2 delete-volume --volume-id "$v" && echo "  deleted volume $v"
done

for s in $data_snaps $ami_snaps; do
  aws ec2 delete-snapshot --snapshot-id "$s" && echo "  deleted snapshot $s"
done

for sg in $(ids ec2 describe-security-groups --filters Name=group-name,Values=web-sg "Name=tag:$SEED_KEY,Values=05-ebs-amis" --query 'SecurityGroups[].GroupId'); do
  aws ec2 delete-security-group --group-id "$sg" >/dev/null && echo "  deleted security group web-sg ($sg)"
done
aws ec2 describe-key-pairs --key-names amigos-key >/dev/null 2>&1 &&
  echo "  kept key pair amigos-key (the course's SSH key - later sections use it)"
echo "Done. Nothing from this section is billing any more."
