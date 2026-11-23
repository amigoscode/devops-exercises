#!/usr/bin/env bash
# Deletes what "03 - IAM" created: dev-alice, the developers group and the
# S3ReadOnlyCourse policy.
#
# NEVER deletes amigos-admin or the Admins group: from this section on that is how
# you sign in, and deleting it would lock you out (back to root). The account
# password policy is left in place too - it is a good setting to keep.
#
# Runs inside the AWS CLI container, after lib/aws.sh (which has the delete_* helpers).

signed_in || { echo "Not signed in - run: ${LAUNCHER:-./course.sh} login"; exit 1; }
POLICY_ARN="arn:aws:iam::$ACCOUNT:policy/S3ReadOnlyCourse"

echo "Deleting what section 03 created (amigos-admin and Admins are kept):"
delete_user   dev-alice
delete_group  developers
delete_policy "$POLICY_ARN"
echo "Done."
