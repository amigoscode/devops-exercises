#!/usr/bin/env bash
# Grades "03 - IAM" against the student's real AWS account.
#
# Runs inside the AWS CLI container, after lib/aws.sh (which provides ok/no/score
# and the signed-in check). Read-only: nothing here changes the account - even the
# policy simulation in 2.3 only asks IAM "would this be allowed?".

require_login \
  "1.1 group 'Admins' with AdministratorAccess" \
  "1.2 user 'amigos-admin' with console access, in Admins" \
  "1.3 amigos-admin has MFA" \
  "1.4 the checker is signed in as amigos-admin" \
  "2.1 user 'dev-alice' in group 'developers'" \
  "2.2 your policy 'S3ReadOnlyCourse' is attached to developers" \
  "2.3 dev-alice can read S3 but not write or delete" \
  "3.1 a password policy of 12+ characters" \
  "3.2 your users and policy are tagged course=aws-essentials"

# ---- small IAM helpers -------------------------------------------------------
gt0()          { [ "${1:-0}" -gt 0 ] 2>/dev/null; }
has_user()     { aws iam get-user  --user-name  "$1" >/dev/null 2>&1; }
has_group()    { aws iam get-group --group-name "$1" >/dev/null 2>&1; }
in_group()     { gt0 "$(aws iam list-groups-for-user --user-name "$1" \
                   --query "length(Groups[?GroupName=='$2'])" --output text 2>/dev/null)"; }
group_policy() { gt0 "$(aws iam list-attached-group-policies --group-name "$1" \
                   --query "length(AttachedPolicies[?PolicyName=='$2'])" --output text 2>/dev/null)"; }
tagged()       { # tagged user|policy <name-or-arn>
  local kind="$1" name="$2" v
  case "$kind" in
    user)   v="$(aws iam list-user-tags   --user-name  "$name" --query "Tags[?Key=='$TAG_KEY'].Value | [0]" --output text 2>/dev/null)" ;;
    policy) v="$(aws iam list-policy-tags --policy-arn "$name" --query "Tags[?Key=='$TAG_KEY'].Value | [0]" --output text 2>/dev/null)" ;;
  esac
  [ "$v" = "$TAG_VALUE" ]
}

POLICY_ARN="arn:aws:iam::$ACCOUNT:policy/S3ReadOnlyCourse"
ALICE_ARN="arn:aws:iam::$ACCOUNT:user/dev-alice"

echo "Tier 1 - Stop using root"

if ! has_group Admins; then
  no "1.1 create a user group named 'Admins'"
elif ! group_policy Admins AdministratorAccess; then
  no "1.1 attach the AWS managed policy 'AdministratorAccess' to the Admins group"
else
  ok "1.1 group 'Admins' with AdministratorAccess"
fi

if ! has_user amigos-admin; then
  no "1.2 create a user named 'amigos-admin'"
elif ! aws iam get-login-profile --user-name amigos-admin >/dev/null 2>&1; then
  no "1.2 give amigos-admin console access (Security credentials → Enable console access)"
elif ! in_group amigos-admin Admins; then
  no "1.2 add amigos-admin to the Admins group"
else
  ok "1.2 user 'amigos-admin' with console access, in Admins"
fi

mfa="$(aws iam list-mfa-devices --user-name amigos-admin --query 'length(MFADevices)' --output text 2>/dev/null)"
if gt0 "$mfa"; then
  ok "1.3 amigos-admin has MFA"
else
  no "1.3 assign an MFA device to amigos-admin (Users → amigos-admin → Security credentials)"
fi

case "$CALLER_ARN" in
  "arn:aws:iam::$ACCOUNT:user/amigos-admin")
    ok "1.4 the checker is signed in as amigos-admin" ;;
  *:root)
    no "1.4 sign the checker in as amigos-admin, not root: ./course.sh logout, then ./course.sh login" ;;
  *)
    no "1.4 the checker is signed in as ${CALLER_ARN##*/}, not amigos-admin: ./course.sh logout, then login" ;;
esac

echo "Tier 2 - Least privilege"

if ! has_group developers; then
  no "2.1 create a user group named 'developers'"
elif ! has_user dev-alice; then
  no "2.1 create a user named 'dev-alice'"
elif ! in_group dev-alice developers; then
  no "2.1 add dev-alice to the developers group"
else
  ok "2.1 user 'dev-alice' in group 'developers'"
fi

if ! aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  no "2.2 create your own policy named 'S3ReadOnlyCourse' (Policies → Create policy → JSON)"
elif ! group_policy developers S3ReadOnlyCourse; then
  no "2.2 attach S3ReadOnlyCourse to the developers group"
else
  ok "2.2 your policy 'S3ReadOnlyCourse' is attached to developers"
fi

# 2.3: ask IAM what dev-alice may do, through every policy and group she has. The
# resources are section 04's files bucket, so this still passes once she is narrowed
# down to that one bucket there (a policy on "*" covers it too).
if ! has_user dev-alice; then
  no "2.3 dev-alice can read S3 but not write or delete - create dev-alice first (2.1)"
else
  BUCKET="arn:aws:s3:::amigos-files-$ACCOUNT"
  cant_read="" can_write="" errors=""
  while read -r action resource; do
    d="$(decision "$ALICE_ARN" "s3:$action" "$resource")"
    [ -n "$d" ] || errors=1
    [ "$d" = allowed ] || cant_read="$cant_read $action"
  done <<READS
ListAllMyBuckets *
ListBucket $BUCKET
GetObject $BUCKET/notes/hello.txt
READS
  while read -r action resource; do
    [ "$(decision "$ALICE_ARN" "s3:$action" "$resource")" = allowed ] && can_write="$can_write $action"
  done <<WRITES
PutObject $BUCKET/notes/hello.txt
DeleteObject $BUCKET/notes/hello.txt
DeleteBucket $BUCKET
WRITES
  if [ -n "$errors" ]; then
    no "2.3 could not run the policy simulation for dev-alice"
  elif [ -n "$can_write" ]; then
    no "2.3 dev-alice has too much access - she is allowed:$can_write (is she in Admins, or has a wider policy?)"
  elif [ -n "$cant_read" ]; then
    no "2.3 dev-alice cannot read yet - denied:$cant_read (is S3ReadOnlyCourse attached to developers?)"
  else
    ok "2.3 dev-alice can read S3 but not write or delete"
  fi
fi

echo "Tier 3 - Account hygiene"

minlen="$(aws iam get-account-password-policy --query 'PasswordPolicy.MinimumPasswordLength' --output text 2>/dev/null)"
if [ -z "$minlen" ]; then
  no "3.1 set an account password policy (Account settings → Password policy → Edit → Custom)"
elif [ "$minlen" -ge 12 ] 2>/dev/null; then
  ok "3.1 a password policy of $minlen+ characters"
else
  no "3.1 raise the password policy's minimum length to 12 (it is $minlen)"
fi

untagged=""
tagged user amigos-admin       || untagged="$untagged amigos-admin"
tagged user dev-alice          || untagged="$untagged dev-alice"
tagged policy "$POLICY_ARN"    || untagged="$untagged S3ReadOnlyCourse"
if [ -z "$untagged" ]; then
  ok "3.2 your users and policy are tagged course=aws-essentials"
else
  no "3.2 add the tag course = aws-essentials to:$untagged"
fi

score
[[ $fail -eq 0 ]] && echo "🎉 Root is locked away, and people get only what they need."
exit 0
