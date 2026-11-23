#!/usr/bin/env bash
# Sets up "04 - S3" so it can be done on its own: makes sure the S3ReadOnlyCourse
# policy from section 03 exists (you narrow it in 3.4), and that the account has a
# default VPC for the server in Tier 4. Anything it creates is tagged
# seeded-by=04-s3, and only that is deleted again by clean.sh. Your buckets, the role
# and the server are not created here - that is the exercise.
#
# Runs inside the AWS CLI container, after lib/aws.sh.

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }
POLICY_ARN="arn:aws:iam::$ACCOUNT:policy/S3ReadOnlyCourse"
TAGS="Key=$TAG_KEY,Value=$TAG_VALUE Key=$SEED_KEY,Value=04-s3"

echo "Setting up 04-s3:"

if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  echo "  found policy S3ReadOnlyCourse (from section 03) - using it"
else
  # shellcheck disable=SC2086
  aws iam create-policy --policy-name S3ReadOnlyCourse --tags $TAGS \
    --description "Read S3 (AWS Essentials, created by 04-s3 setup)" \
    --policy-document '{
      "Version": "2012-10-17",
      "Statement": [{ "Sid": "ReadS3", "Effect": "Allow",
        "Action": ["s3:ListAllMyBuckets", "s3:ListBucket", "s3:GetObject"], "Resource": "*" }]
    }' >/dev/null || exit 1
  echo "  created policy S3ReadOnlyCourse (what section 03 builds)"
fi

vpc="$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text 2>/dev/null)"
if [ -n "$vpc" ] && [ "$vpc" != None ]; then
  echo "  found the default VPC $vpc"
else
  aws ec2 create-default-vpc >/dev/null || exit 1
  echo "  created a default VPC (it is free - section 06 builds your own)"
fi

if ! aws ec2 describe-key-pairs --key-names amigos-key >/dev/null 2>&1; then
  echo "  no key pair amigos-key yet - Tier 4 needs it: create it as in section 02, task 1.2"
fi

echo
echo "Your bucket names (they must be unique across all of AWS, so they end in your account ID):"
echo "  amigos-files-$ACCOUNT"
echo "  amigos-site-$ACCOUNT"
