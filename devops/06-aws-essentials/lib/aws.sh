# Shared helpers for the AWS Essentials checks.
#
# The runner streams this file, followed by a section's verify.sh / seed.sh /
# clean.sh, into the AWS CLI container. So every script below can call `aws`
# directly, already signed in to the student's account, in region $AWS_REGION.
set -uo pipefail

# Every resource the course asks you to create carries this tag, so checks only
# ever look at course resources, and clean-up only ever deletes course resources.
TAG_KEY="course"
TAG_VALUE="aws-essentials"

pass=0; fail=0
ok()   { printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no()   { printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
note() { printf '     %s\n' "$1"; }

score() {
  echo
  echo "Score: $pass passed, $fail failed."
}

# Sets ACCOUNT and CALLER_ARN. Fails when the checker is not signed in.
signed_in() {
  local id
  id="$(aws sts get-caller-identity --query '[Account, Arn]' --output text 2>/dev/null)" || return 1
  ACCOUNT="${id%%[[:space:]]*}"
  CALLER_ARN="${id##*[[:space:]]}"
  [ -n "$ACCOUNT" ]
}

# When the checker is not signed in, nothing can be checked: print every graded
# task as not done, pointing at `login`, and stop.
#   require_login "1.3 Root user has MFA" "2.1 ..."
require_login() {
  signed_in && return 0
  echo "  The checker is not signed in to your AWS account (or the sign-in expired)."
  echo "  Sign in with:  ${LAUNCHER:-./course.sh} login"
  echo
  local t
  for t in "$@"; do no "$t - sign the checker in first"; done
  score
  exit 0
}

# ---- IAM ------------------------------------------------------------------------
# Asks IAM "would this principal be allowed this action on this resource?". Read-only.
#   decision <principal-arn> <action> [resource-arn]  ->  allowed | implicitDeny | explicitDeny
decision() {
  aws iam simulate-principal-policy --policy-source-arn "$1" --action-names "$2" \
    ${3:+--resource-arns "$3"} --query 'EvaluationResults[0].EvalDecision' --output text 2>/dev/null
}

# Resources a section's seed.sh creates carry this tag too (value: the section), so
# its clean.sh deletes only what it created - never what you built yourself.
SEED_KEY="seeded-by"

# ---- S3 -------------------------------------------------------------------------
# Prints the bucket's region, or fails if the bucket is not in this account.
bucket_region() {
  local loc
  loc="$(aws s3api get-bucket-location --bucket "$1" --query LocationConstraint --output text 2>/dev/null)" || return 1
  case "$loc" in None|null|"") echo us-east-1 ;; EU) echo eu-west-1 ;; *) echo "$loc" ;; esac
}

# ---- clean-up helpers (used by the sections' clean.sh) --------------------------
# One id per line from a text query, skipping empty results.
ids() { aws "$@" --output text 2>/dev/null | tr '\t' '\n' | grep -v '^None$' | grep -v '^$'; }

delete_user() {
  local u="$1" x
  aws iam get-user --user-name "$u" >/dev/null 2>&1 || return 0
  for x in $(ids iam list-groups-for-user --user-name "$u" --query 'Groups[].GroupName'); do
    aws iam remove-user-from-group --user-name "$u" --group-name "$x"
  done
  aws iam delete-login-profile --user-name "$u" >/dev/null 2>&1 || true
  for x in $(ids iam list-access-keys --user-name "$u" --query 'AccessKeyMetadata[].AccessKeyId'); do
    aws iam delete-access-key --user-name "$u" --access-key-id "$x"
  done
  for x in $(ids iam list-mfa-devices --user-name "$u" --query 'MFADevices[].SerialNumber'); do
    aws iam deactivate-mfa-device --user-name "$u" --serial-number "$x"
    case "$x" in *:mfa/*) aws iam delete-virtual-mfa-device --serial-number "$x" >/dev/null 2>&1 || true ;; esac
  done
  for x in $(ids iam list-signing-certificates --user-name "$u" --query 'Certificates[].CertificateId'); do
    aws iam delete-signing-certificate --user-name "$u" --certificate-id "$x"
  done
  for x in $(ids iam list-ssh-public-keys --user-name "$u" --query 'SSHPublicKeys[].SSHPublicKeyId'); do
    aws iam delete-ssh-public-key --user-name "$u" --ssh-public-key-id "$x"
  done
  for x in $(ids iam list-service-specific-credentials --user-name "$u" --query 'ServiceSpecificCredentials[].ServiceSpecificCredentialId'); do
    aws iam delete-service-specific-credential --user-name "$u" --service-specific-credential-id "$x"
  done
  for x in $(ids iam list-attached-user-policies --user-name "$u" --query 'AttachedPolicies[].PolicyArn'); do
    aws iam detach-user-policy --user-name "$u" --policy-arn "$x"
  done
  for x in $(ids iam list-user-policies --user-name "$u" --query 'PolicyNames'); do
    aws iam delete-user-policy --user-name "$u" --policy-name "$x"
  done
  aws iam delete-user --user-name "$u" && echo "  deleted user $u"
}

delete_group() {
  local g="$1" x
  aws iam get-group --group-name "$g" >/dev/null 2>&1 || return 0
  for x in $(ids iam get-group --group-name "$g" --query 'Users[].UserName'); do
    aws iam remove-user-from-group --group-name "$g" --user-name "$x"
  done
  for x in $(ids iam list-attached-group-policies --group-name "$g" --query 'AttachedPolicies[].PolicyArn'); do
    aws iam detach-group-policy --group-name "$g" --policy-arn "$x"
  done
  for x in $(ids iam list-group-policies --group-name "$g" --query 'PolicyNames'); do
    aws iam delete-group-policy --group-name "$g" --policy-name "$x"
  done
  aws iam delete-group --group-name "$g" && echo "  deleted group $g"
}

delete_role() {
  local r="$1" x
  aws iam get-role --role-name "$r" >/dev/null 2>&1 || return 0
  for x in $(ids iam list-instance-profiles-for-role --role-name "$r" --query 'InstanceProfiles[].InstanceProfileName'); do
    aws iam remove-role-from-instance-profile --instance-profile-name "$x" --role-name "$r"
    # The console creates a profile with the role's name; only delete that one.
    [ "$x" = "$r" ] && aws iam delete-instance-profile --instance-profile-name "$x"
  done
  for x in $(ids iam list-attached-role-policies --role-name "$r" --query 'AttachedPolicies[].PolicyArn'); do
    aws iam detach-role-policy --role-name "$r" --policy-arn "$x"
  done
  for x in $(ids iam list-role-policies --role-name "$r" --query 'PolicyNames'); do
    aws iam delete-role-policy --role-name "$r" --policy-name "$x"
  done
  aws iam delete-role --role-name "$r" && echo "  deleted role $r"
}

delete_policy() {
  local arn="$1" x
  aws iam get-policy --policy-arn "$arn" >/dev/null 2>&1 || return 0
  for x in $(ids iam list-entities-for-policy --policy-arn "$arn" --query 'PolicyUsers[].UserName'); do
    aws iam detach-user-policy --user-name "$x" --policy-arn "$arn"
  done
  for x in $(ids iam list-entities-for-policy --policy-arn "$arn" --query 'PolicyGroups[].GroupName'); do
    aws iam detach-group-policy --group-name "$x" --policy-arn "$arn"
  done
  for x in $(ids iam list-entities-for-policy --policy-arn "$arn" --query 'PolicyRoles[].RoleName'); do
    aws iam detach-role-policy --role-name "$x" --policy-arn "$arn"
  done
  for x in $(ids iam list-policy-versions --policy-arn "$arn" --query 'Versions[?!IsDefaultVersion].VersionId'); do
    aws iam delete-policy-version --policy-arn "$arn" --version-id "$x"
  done
  aws iam delete-policy --policy-arn "$arn" && echo "  deleted policy ${arn##*/}"
}

# Is this role / policy one that a seed.sh created (tag seeded-by=<section>)?
seeded_role()   { [ "$(aws iam list-role-tags   --role-name  "$1" --query "Tags[?Key=='$SEED_KEY'].Value | [0]" --output text 2>/dev/null)" = "$2" ]; }
seeded_policy() { [ "$(aws iam list-policy-tags --policy-arn "$1" --query "Tags[?Key=='$SEED_KEY'].Value | [0]" --output text 2>/dev/null)" = "$2" ]; }

# Empties a bucket completely - every object, every old version, every delete
# marker, every unfinished upload - then deletes it. Works in any region.
delete_bucket() {
  local b="$1" r page x
  r="$(bucket_region "$b")" || return 0
  while :; do
    page="$(aws s3api list-object-versions --bucket "$b" --region "$r" --max-keys 1000 --no-paginate --output json 2>/dev/null)" || break
    [ -n "$page" ] || page='{}'
    page="$(jq -c '{Objects: [(.Versions // [])[], (.DeleteMarkers // [])[] | {Key, VersionId}], Quiet: true}' <<<"$page")"
    [ "$(jq '.Objects | length' <<<"$page")" -gt 0 ] || break
    aws s3api delete-objects --bucket "$b" --region "$r" --delete "$page" >/dev/null || break
  done
  aws s3api list-multipart-uploads --bucket "$b" --region "$r" --output json 2>/dev/null \
    | jq -r '(.Uploads // [])[] | [.Key, .UploadId] | @tsv' \
    | while IFS=$'\t' read -r k x; do
        aws s3api abort-multipart-upload --bucket "$b" --region "$r" --key "$k" --upload-id "$x"
      done
  aws s3api delete-bucket --bucket "$b" --region "$r" && echo "  deleted bucket $b (and every version in it)"
}

# ---- EC2 ------------------------------------------------------------------------
# Looks inside a server without the student's key: makes a throwaway key, hands it to
# the server through EC2 Instance Connect (it is accepted for 60 seconds), logs in as
# ec2-user and runs <script> with sudo. Sets PROBE_OUT (what the script printed) and
# PROBE_ERR (why it could not connect).
#   ssh_probe <instance-id> <ip> <script>
ssh_probe() {
  PROBE_OUT="" PROBE_ERR=""
  rm -f /tmp/probe /tmp/probe.pub
  ssh-keygen -q -t ed25519 -N '' -C aws-essentials-checker -f /tmp/probe >/dev/null 2>&1
  if aws ec2-instance-connect send-ssh-public-key --instance-id "$1" --instance-os-user ec2-user \
       --ssh-public-key file:///tmp/probe.pub >/dev/null 2>/tmp/eic-err; then
    PROBE_OUT="$(ssh -i /tmp/probe -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
      "ec2-user@$2" 'sudo bash -s' <<<"$3" 2>/tmp/ssh-err)"
    PROBE_ERR="$(tr '\n' ' ' </tmp/ssh-err)"
  else
    PROBE_ERR="instance connect: $(tr '\n' ' ' </tmp/eic-err)"
  fi
}

# The live (not terminated) instances with this Name tag, running ones first, as a
# JSON array.   instances_named <name>
instances_named() {
  local j
  j="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" \
    Name=instance-state-name,Values=pending,running,stopping,stopped --output json 2>/dev/null)"
  [ -n "$j" ] || j='{}'
  jq -c '[.Reservations[]?.Instances[]?] | (map(select(.State.Name == "running")) + map(select(.State.Name != "running")))' <<<"$j"
}

# The same look inside, for a server with no public IP: the throwaway key is handed to
# both servers, and the checker hops through the first one (a bastion) to reach the
# second on its private IP - what ProxyJump does on your laptop. Sets PROBE_OUT and
# PROBE_ERR like ssh_probe.
#   ssh_probe_via <bastion-id> <bastion-public-ip> <instance-id> <private-ip> <script>
ssh_probe_via() {
  PROBE_OUT="" PROBE_ERR=""
  rm -f /tmp/probe /tmp/probe.pub
  ssh-keygen -q -t ed25519 -N '' -C aws-essentials-checker -f /tmp/probe >/dev/null 2>&1
  local i opts="-i /tmp/probe -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
  for i in "$1" "$3"; do
    aws ec2-instance-connect send-ssh-public-key --instance-id "$i" --instance-os-user ec2-user \
      --ssh-public-key file:///tmp/probe.pub >/dev/null 2>/tmp/eic-err ||
      { PROBE_ERR="instance connect ($i): $(tr '\n' ' ' </tmp/eic-err)"; return; }
  done
  # shellcheck disable=SC2086
  PROBE_OUT="$(ssh $opts -o ProxyCommand="ssh $opts -W %h:%p ec2-user@$2" \
    "ec2-user@$4" 'sudo bash -s' <<<"$5" 2>/tmp/ssh-err)"
  PROBE_ERR="$(tr '\n' ' ' </tmp/ssh-err)"
}
