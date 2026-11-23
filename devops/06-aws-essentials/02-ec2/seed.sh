#!/usr/bin/env bash
# Sets up "02 - EC2": makes sure the account has a default VPC (the launch wizard
# puts the server in it) and creates one if it was deleted. A default VPC is free,
# and clean.sh never deletes it.
#
# Runs inside the AWS CLI container, after lib/aws.sh.

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }

echo "Setting up 02-ec2:"

vpc="$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text 2>/dev/null)"
if [ -n "$vpc" ] && [ "$vpc" != None ]; then
  echo "  found the default VPC $vpc"
else
  aws ec2 create-default-vpc >/dev/null || exit 1
  echo "  created a default VPC (it is free - section 06 builds your own)"
fi

echo
echo "Ready for the console: security group web-sg, key pair amigos-key, then the instance amigos-web."
