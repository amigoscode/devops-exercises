#!/usr/bin/env bash
# Sets up "06 - VPC". You build this whole section yourself, starting from an empty
# network, so there is nothing to create for you. It only checks what you need:
#   - the key pair amigos-key from section 02 (it can't be made for you - only you
#     may hold its private key)
#   - no amigos-vpc left over from an earlier try (reset deletes it)
#
# Runs inside the AWS CLI container, after lib/aws.sh.

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }

echo "Setting up 06-vpc:"
if aws ec2 describe-key-pairs --key-names amigos-key >/dev/null 2>&1; then
  echo "  found key pair amigos-key"
else
  echo "  no key pair amigos-key yet - create it first, as in section 02 task 1.2"
fi
old="$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=amigos-vpc --query 'Vpcs[].VpcId' --output text 2>/dev/null)"
if [ -n "$old" ] && [ "$old" != None ]; then
  echo "  you already have amigos-vpc ($old) - carry on with it, or start over: ${LAUNCHER:-./course.sh} reset 06-vpc"
fi
echo
echo "Ready for the console: create amigos-vpc (VPC → Your VPCs → Create VPC → VPC only)."
