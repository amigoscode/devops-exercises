#!/usr/bin/env bash
# Sets up "05 - EBS and AMIs" so it can be done on its own. Makes sure these exist,
# and creates whatever is missing:
#   - a default VPC (the launch wizard puts the servers in it)
#   - the security group web-sg from section 02: HTTP from anywhere, SSH from the
#     IP this command runs from (your laptop, or your Codespace)
# What it creates is tagged seeded-by=05-ebs-amis, and only that is deleted by clean.sh.
# The key pair amigos-key can't be made for you - only you may hold its private key.
#
# Runs inside the AWS CLI container, after lib/aws.sh.

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }
SEED=05-ebs-amis

echo "Setting up $SEED:"

vpc="$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text 2>/dev/null)"
if [ -n "$vpc" ] && [ "$vpc" != None ]; then
  echo "  found the default VPC $vpc"
else
  vpc="$(aws ec2 create-default-vpc --query Vpc.VpcId --output text)" || exit 1
  echo "  created a default VPC (it is free - section 06 builds your own)"
fi

sg="$(aws ec2 describe-security-groups --filters Name=group-name,Values=web-sg "Name=vpc-id,Values=$vpc" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)"
if [ -n "$sg" ] && [ "$sg" != None ]; then
  echo "  found security group web-sg ($sg) - using it"
else
  my_ip="$(curl -s -m 5 https://checkip.amazonaws.com | tr -d '[:space:]')"
  [ -n "$my_ip" ] || { echo "  could not work out your IP address - are you online?"; exit 1; }
  sg="$(aws ec2 create-security-group --group-name web-sg --description "web and ssh" --vpc-id "$vpc" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=$TAG_KEY,Value=$TAG_VALUE},{Key=$SEED_KEY,Value=$SEED}]" \
    --query GroupId --output text)" || exit 1
  aws ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null
  aws ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr "$my_ip/32" >/dev/null
  echo "  created security group web-sg ($sg): HTTP from anywhere, SSH from $my_ip/32 (what section 02 builds)"
fi

if aws ec2 describe-key-pairs --key-names amigos-key >/dev/null 2>&1; then
  echo "  found key pair amigos-key"
else
  echo "  no key pair amigos-key yet - create it first, as in section 02 task 1.2"
fi

echo
echo "Ready for the console: launch amigos-data, then create the volume data-vol in its zone."
