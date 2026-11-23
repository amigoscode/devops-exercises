#!/usr/bin/env bash
# Grades "04 - S3" against the student's real AWS account.
#
# Runs inside the AWS CLI container, after lib/aws.sh. Read-only: it reads bucket
# settings, asks IAM "would this be allowed?" and visits the website like any
# browser would. For Tier 4 it logs in to amigos-reader over SSH with a throwaway key
# (EC2 Instance Connect, valid 60 seconds) and, from the server, only reads: the SSH
# log, the server's identity, and whether the role can see each bucket.

require_login \
  "1.1 bucket 'amigos-files-<account-id>' in us-east-1, tagged" \
  "1.2 the files bucket blocks all public access" \
  "1.3 notes/hello.txt is in the files bucket" \
  "2.1 versioning is on for the files bucket" \
  "2.2 notes/hello.txt has an older version" \
  "2.4 a lifecycle rule cleans up old versions" \
  "3.1 bucket 'amigos-site-<account-id>' hosts a static website" \
  "3.2 a bucket policy lets anyone read the site - and only read" \
  "3.3 your website answers on the internet" \
  "3.4 S3ReadOnlyCourse reaches only the files bucket" \
  "4.1 role 'ec2-s3-reader' for EC2 with S3ReadOnlyCourse, tagged" \
  "4.2 instance 'amigos-reader' runs with the role ec2-s3-reader" \
  "4.3 you logged in to amigos-reader over SSH with amigos-key" \
  "4.4 on the server, the role reads the files bucket and nothing else"

FILES="amigos-files-$ACCOUNT"
SITE="amigos-site-$ACCOUNT"
POLICY_ARN="arn:aws:iam::$ACCOUNT:policy/S3ReadOnlyCourse"
FREE_TYPES=" t3.micro t3.small t4g.micro t4g.small t2.micro "
URL="http://$SITE.s3-website-us-east-1.amazonaws.com"

echo "Your buckets: $FILES and $SITE"
echo

# ---- small S3 helpers (bucket, region) -----------------------------------------
tagged_bucket() {
  [ "$(aws s3api get-bucket-tagging --bucket "$1" --region "$2" \
       --query "TagSet[?Key=='$TAG_KEY'].Value | [0]" --output text 2>/dev/null)" = "$TAG_VALUE" ]
}
block_all() { # all four Block Public Access switches on?
  aws s3api get-public-access-block --bucket "$1" --region "$2" --output json 2>/dev/null \
    | jq -e '.PublicAccessBlockConfiguration | [.BlockPublicAcls, .IgnorePublicAcls,
             .BlockPublicPolicy, .RestrictPublicBuckets] | all' >/dev/null
}
has_key() { aws s3api head-object --bucket "$1" --region "$2" --key "$3" >/dev/null 2>&1; }

FR="$(bucket_region "$FILES")"   # empty when the bucket does not exist
SR="$(bucket_region "$SITE")"

echo "Tier 1 - A private bucket"

if [ -z "$FR" ]; then
  no "1.1 create a bucket named $FILES (S3 → Create bucket, region us-east-1)"
elif [ "$FR" != us-east-1 ]; then
  no "1.1 $FILES is in $FR - buckets can't move: delete it and create it again in us-east-1"
elif ! tagged_bucket "$FILES" "$FR"; then
  no "1.1 tag $FILES with course = aws-essentials (bucket → Properties → Tags)"
else
  ok "1.1 bucket $FILES in us-east-1, tagged"
fi

if [ -z "$FR" ]; then
  no "1.2 the files bucket blocks all public access - create it first (1.1)"
elif ! block_all "$FILES" "$FR"; then
  no "1.2 turn all four Block Public Access settings back on for $FILES (Permissions tab)"
elif [ "$(aws s3api get-bucket-policy-status --bucket "$FILES" --region "$FR" \
          --query PolicyStatus.IsPublic --output text 2>/dev/null)" = True ]; then
  no "1.2 $FILES has a public bucket policy - delete it (Permissions → Bucket policy)"
else
  ok "1.2 the files bucket blocks all public access"
fi

if [ -z "$FR" ]; then
  no "1.3 notes/hello.txt is in the files bucket - create the bucket first (1.1)"
elif has_key "$FILES" "$FR" notes/hello.txt; then
  ok "1.3 notes/hello.txt is in the files bucket"
elif has_key "$FILES" "$FR" hello.txt; then
  no "1.3 hello.txt is at the top of the bucket - it goes inside a folder named notes"
else
  no "1.3 create a folder 'notes' in $FILES and upload hello.txt into it"
fi

echo "Tier 2 - Versioning and lifecycle"

if [ -z "$FR" ]; then
  no "2.1 versioning is on for the files bucket - create the bucket first (1.1)"
else
  v="$(aws s3api get-bucket-versioning --bucket "$FILES" --region "$FR" --query Status --output text 2>/dev/null)"
  case "$v" in
    Enabled)   ok "2.1 versioning is on for the files bucket" ;;
    Suspended) no "2.1 versioning is suspended on $FILES - enable it again (Properties → Bucket Versioning)" ;;
    *)         no "2.1 turn on versioning for $FILES (Properties → Bucket Versioning → Edit → Enable)" ;;
  esac
fi

if [ -z "$FR" ]; then
  no "2.2 notes/hello.txt has an older version - create the bucket first (1.1)"
else
  n="$(aws s3api list-object-versions --bucket "$FILES" --region "$FR" --prefix notes/hello.txt --output json 2>/dev/null \
       | jq '[(.Versions // [])[] | select(.Key == "notes/hello.txt")] | length' 2>/dev/null)"
  if [ "${n:-0}" -ge 2 ] 2>/dev/null; then
    if has_key "$FILES" "$FR" notes/hello.txt; then
      ok "2.2 notes/hello.txt has an older version ($n versions)"
    else
      no "2.2 notes/hello.txt is deleted (a delete marker is on top) - Show versions, then delete the delete marker"
    fi
  elif [ "$v" != Enabled ]; then
    no "2.2 turn on versioning (2.1), then upload a changed hello.txt to notes/ again"
  else
    no "2.2 change hello.txt on your computer and upload it to notes/ again - versioning keeps the old one"
  fi
fi

if [ -z "$FR" ]; then
  no "2.4 a lifecycle rule cleans up old versions - create the bucket first (1.1)"
else
  rules="$(aws s3api get-bucket-lifecycle-configuration --bucket "$FILES" --region "$FR" --output json 2>/dev/null)"
  [ -n "$rules" ] || rules='{}'
  missing="$(jq -r '[(.Rules // [])[] | select(.Status == "Enabled")] as $on
    | [ (if any($on[]; (.NoncurrentVersionTransitions // []) | any(.StorageClass == "STANDARD_IA")) then empty
         else "move noncurrent versions to Standard-IA" end),
        (if any($on[]; .NoncurrentVersionExpiration.NoncurrentDays != null) then empty
         else "permanently delete noncurrent versions" end),
        (if any($on[]; .AbortIncompleteMultipartUpload.DaysAfterInitiation != null) then empty
         else "delete incomplete multipart uploads" end) ]
    | join(", ")' <<<"$rules" 2>/dev/null)"
  if [ "$rules" = '{}' ]; then
    no "2.4 add a lifecycle rule to $FILES (Management → Create lifecycle rule)"
  elif [ -n "$missing" ]; then
    no "2.4 your lifecycle rules don't yet: $missing"
  else
    ok "2.4 a lifecycle rule cleans up old versions"
  fi
fi

echo "Tier 3 - A public website, on purpose"

if [ -z "$SR" ]; then
  no "3.1 create a second bucket named $SITE (us-east-1)"
elif [ "$SR" != us-east-1 ]; then
  no "3.1 $SITE is in $SR - delete it and create it again in us-east-1"
else
  web="$(aws s3api get-bucket-website --bucket "$SITE" --region "$SR" --output json 2>/dev/null)"
  if [ -z "$web" ]; then
    no "3.1 turn on static website hosting for $SITE (Properties → Static website hosting)"
  elif [ "$(jq -r '.IndexDocument.Suffix // ""' <<<"$web")" != index.html ]; then
    no "3.1 set the index document to index.html (Properties → Static website hosting → Edit)"
  elif [ "$(jq -r '.ErrorDocument.Key // ""' <<<"$web")" != error.html ]; then
    no "3.1 set the error document to error.html (Properties → Static website hosting → Edit)"
  elif ! has_key "$SITE" "$SR" index.html; then
    no "3.1 upload website/index.html to the top of $SITE"
  elif ! has_key "$SITE" "$SR" error.html; then
    no "3.1 upload website/error.html to the top of $SITE"
  elif ! tagged_bucket "$SITE" "$SR"; then
    no "3.1 tag $SITE with course = aws-essentials (bucket → Properties → Tags)"
  else
    ok "3.1 bucket $SITE hosts a static website"
  fi
fi

if [ -z "$SR" ]; then
  no "3.2 a bucket policy lets anyone read the site - create $SITE first (3.1)"
else
  pol="$(aws s3api get-bucket-policy --bucket "$SITE" --region "$SR" --query Policy --output text 2>/dev/null)"
  if [ -z "$pol" ]; then
    acct_block="$(aws s3control get-public-access-block --account-id "$ACCOUNT" \
      --query 'PublicAccessBlockConfiguration.BlockPublicPolicy' --output text 2>/dev/null)"
    if [ "$acct_block" = True ]; then
      no "3.2 your account blocks public bucket policies - see the note in 3.2, then add the policy"
    elif aws s3api get-public-access-block --bucket "$SITE" --region "$SR" \
           --query 'PublicAccessBlockConfiguration.BlockPublicPolicy' --output text 2>/dev/null | grep -q True; then
      no "3.2 turn off Block Public Access for $SITE (Permissions → Block public access → Edit), then add the policy"
    else
      no "3.2 add the bucket policy from the README to $SITE (Permissions → Bucket policy → Edit)"
    fi
  else
    # Look only at statements that allow everyone ("Principal": "*").
    verdict="$(jq -r --arg objects "arn:aws:s3:::$SITE/*" '
      def list: if type == "array" then .[] else . end;
      [ (.Statement // []) | list | select(.Effect == "Allow")
        | select(.Principal | (if type == "object" then .AWS else . end) | [list] | any(. == "*")) ] as $pub
      | ([ $pub[] | (.Action // []) | list | ascii_downcase ] | unique) as $acts
      | ([ $pub[] | (.Resource // []) | list ] | unique) as $res
      | if ($pub | length) == 0 then "none"
        elif any($pub[]; .NotAction != null) then "wide NotAction (that allows everything else)"
        elif ($acts - ["s3:getobject"] | length) > 0 then "wide " + ($acts - ["s3:getobject"] | join(" "))
        elif ($res - [$objects] | length) > 0 then "resource " + ($res - [$objects] | join(" "))
        elif ($res | length) == 0 then "resource none"
        else "ok" end' <<<"$pol" 2>/dev/null)"
    case "$verdict" in
      ok)         ok "3.2 a bucket policy lets anyone read the site - and only read" ;;
      none)       no "3.2 the bucket policy doesn't allow everyone - it needs \"Principal\": \"*\" and \"Effect\": \"Allow\"" ;;
      wide*)      no "3.2 the policy gives everyone more than reading: ${verdict#wide } - allow only s3:GetObject" ;;
      resource*)  no "3.2 the policy's Resource must be exactly arn:aws:s3:::$SITE/* (it has: ${verdict#resource })" ;;
      *)          no "3.2 could not read the bucket policy on $SITE - is it valid JSON?" ;;
    esac
  fi
fi

if [ -z "$SR" ]; then
  no "3.3 your website answers on the internet - create $SITE first (3.1)"
else
  home="$(curl -s -o /tmp/home.html -w '%{http_code}' --max-time 15 "$URL/" 2>/dev/null)"
  miss="$(curl -s -o /tmp/miss.html -w '%{http_code}' --max-time 15 "$URL/nope" 2>/dev/null)"
  case "$home" in
    200)
      # Without a working error document S3 sends its own page, a list of "Code: ..." lines.
      if [ "$miss" != 403 ] && [ "$miss" != 404 ]; then
        no "3.3 $URL/nope answered $miss - expected your error page"
      elif grep -q '<li>Code:' /tmp/miss.html; then
        no "3.3 $URL/nope shows S3's own error page, not error.html - upload error.html and set it as the error document"
      else
        ok "3.3 your website answers on the internet"
        note "open it: $URL"
      fi ;;
    403) no "3.3 $URL answers 403 Forbidden - Block Public Access or the bucket policy still stops it (3.2)" ;;
    404) no "3.3 $URL answers 404 - is static website hosting on, and index.html uploaded (3.1)?" ;;
    *)   no "3.3 no answer from $URL - is static website hosting on (3.1)?" ;;
  esac
fi

# 3.4: simulate the policy document itself - "if something had only this policy,
# what could it do?". Tier 4 then proves it on a real server.
pver="$(aws iam get-policy --policy-arn "$POLICY_ARN" --query Policy.DefaultVersionId --output text 2>/dev/null)"
pdoc=""
[ -n "$pver" ] && pdoc="$(aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$pver" \
  --query PolicyVersion.Document --output json 2>/dev/null)"
pdecision() {
  aws iam simulate-custom-policy --policy-input-list "$pdoc" --action-names "$1" \
    ${2:+--resource-arns "$2"} --query 'EvaluationResults[0].EvalDecision' --output text 2>/dev/null
}
if [ -z "$pdoc" ]; then
  no "3.4 the policy S3ReadOnlyCourse is missing - run: ${LAUNCHER:-./course.sh} start 04-s3 (it creates it)"
else
  allow="" deny="" errors=""
  while read -r action resource; do
    d="$(pdecision "s3:$action" "$resource")"
    [ -n "$d" ] || errors=1
    [ "$d" = allowed ] || allow="$allow $action"
  done <<MUST
ListAllMyBuckets *
ListBucket arn:aws:s3:::$FILES
GetObject arn:aws:s3:::$FILES/notes/hello.txt
MUST
  while read -r what action resource; do
    [ "$(pdecision "s3:$action" "$resource")" = allowed ] && deny="$deny $what"
  done <<MUST_NOT
read-the-site GetObject arn:aws:s3:::$SITE/index.html
list-the-site ListBucket arn:aws:s3:::$SITE
write-files PutObject arn:aws:s3:::$FILES/notes/hello.txt
delete-files DeleteObject arn:aws:s3:::$FILES/notes/hello.txt
MUST_NOT
  if [ -n "$errors" ]; then
    no "3.4 could not run the policy simulation for S3ReadOnlyCourse - is it valid JSON?"
  elif [ -n "$allow" ]; then
    no "3.4 S3ReadOnlyCourse can't:$allow on $FILES - check both ARNs (bucket, and bucket/*)"
  elif [ -n "$deny" ]; then
    no "3.4 S3ReadOnlyCourse can still:$deny - narrow it to $FILES (see 3.4)"
  else
    ok "3.4 S3ReadOnlyCourse reaches only the files bucket"
  fi
fi

echo "Tier 4 - A server that reads S3 with a role"

ROLE_OK=""
if ! aws iam get-role --role-name ec2-s3-reader >/dev/null 2>&1; then
  no "4.1 create a role named ec2-s3-reader (IAM → Roles → Create role → AWS service → EC2)"
else
  trust="$(aws iam get-role --role-name ec2-s3-reader --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)"
  [ -n "$trust" ] || trust='{}'
  ec2_trusted="$(jq -r '[(.Statement // [])[] | select(.Effect == "Allow")
      | .Principal.Service // empty | if type == "array" then .[] else . end]
      | any(. == "ec2.amazonaws.com")' <<<"$trust" 2>/dev/null)"
  attached="$(aws iam list-attached-role-policies --role-name ec2-s3-reader \
    --query "length(AttachedPolicies[?PolicyName=='S3ReadOnlyCourse'])" --output text 2>/dev/null)"
  others="$(aws iam list-attached-role-policies --role-name ec2-s3-reader \
    --query "AttachedPolicies[?PolicyName!='S3ReadOnlyCourse'].PolicyName" --output text 2>/dev/null)"
  profiles="$(aws iam list-instance-profiles-for-role --role-name ec2-s3-reader \
    --query 'length(InstanceProfiles)' --output text 2>/dev/null)"
  rtag="$(aws iam list-role-tags --role-name ec2-s3-reader --query "Tags[?Key=='$TAG_KEY'].Value | [0]" --output text 2>/dev/null)"
  if [ "$ec2_trusted" != true ]; then
    no "4.1 ec2-s3-reader must trust the EC2 service (ec2.amazonaws.com) - create it again as AWS service → EC2"
  elif [ "${attached:-0}" -lt 1 ] 2>/dev/null; then
    no "4.1 attach S3ReadOnlyCourse to ec2-s3-reader (role → Permissions → Add permissions)"
  elif [ -n "$others" ] && [ "$others" != None ]; then
    no "4.1 ec2-s3-reader has more policies than S3ReadOnlyCourse: $others - remove them"
  elif [ "${profiles:-0}" -lt 1 ] 2>/dev/null; then
    no "4.1 ec2-s3-reader has no instance profile - create the role in the console as AWS service → EC2"
  elif [ "$rtag" != "$TAG_VALUE" ]; then
    no "4.1 tag ec2-s3-reader with course = aws-essentials (role → Tags)"
  else
    ok "4.1 role 'ec2-s3-reader' for EC2 with S3ReadOnlyCourse, tagged"
    ROLE_OK=1
  fi
fi

inst="$(aws ec2 describe-instances --filters Name=tag:Name,Values=amigos-reader \
  Name=instance-state-name,Values=pending,running,stopping,stopped --output json 2>/dev/null)"
[ -n "$inst" ] || inst='{}'
inst="$(jq -c '[.Reservations[]?.Instances[]?]' <<<"$inst")"
n="$(jq 'length' <<<"$inst")"
I="$(jq -c '(map(select(.State.Name == "running")) + .)[0] // {}' <<<"$inst")"
IID="$(jq -r '.InstanceId // empty' <<<"$I")"
STATE="$(jq -r '.State.Name // empty' <<<"$I")"
PUBLIC_IP="$(jq -r '.PublicIpAddress // empty' <<<"$I")"
MY_IP="$(curl -s -m 5 https://checkip.amazonaws.com 2>/dev/null | tr -d '[:space:]')"

if [ "$n" -eq 0 ]; then
  no "4.2 launch an instance named amigos-reader (EC2 → Launch instances, see 4.2)"
elif [ "$n" -gt 1 ]; then
  no "4.2 you have $n instances named amigos-reader - terminate the extras (each one is billed)"
else
  type="$(jq -r '.InstanceType' <<<"$I")"
  ami="$(aws ec2 describe-images --image-ids "$(jq -r '.ImageId' <<<"$I")" --query 'Images[0].Name' --output text 2>/dev/null)"
  keyname="$(jq -r '.KeyName // ""' <<<"$I")"
  profile="$(jq -r '.IamInstanceProfile.Arn // ""' <<<"$I")"
  itag="$(jq -r --arg k "$TAG_KEY" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""' <<<"$I")"
  sgids="$(jq -r '[.SecurityGroups[]?.GroupId] | join(" ")' <<<"$I")"
  # shellcheck disable=SC2086
  ssh_world="$(aws ec2 describe-security-groups --group-ids $sgids --output json 2>/dev/null | jq -r '
    [.SecurityGroups[]?.IpPermissions[]? | select(.IpProtocol == "-1" or (.IpProtocol == "tcp" and .FromPort <= 22 and .ToPort >= 22))
     | select(([.IpRanges[]?.CidrIp] | index("0.0.0.0/0")) != null or ([.Ipv6Ranges[]?.CidrIpv6] | index("::/0")) != null)] | length > 0')"
  if [ "$STATE" != running ]; then
    no "4.2 amigos-reader is $STATE - start it (Instance state → Start instance)"
  elif [[ "$FREE_TYPES" != *" $type "* ]]; then
    no "4.2 amigos-reader is a $type - use t3.micro"
  elif [ -n "$ami" ] && [ "$ami" != None ] && { [[ "$ami" != al2023-ami-* ]] || [[ "$ami" == al2023-ami-minimal* ]]; }; then
    no "4.2 amigos-reader runs $ami - launch it again from Amazon Linux 2023 (not minimal - it needs the AWS CLI)"
  elif [ "$keyname" != amigos-key ]; then
    no "4.2 amigos-reader was launched with key pair '${keyname:-none}', not amigos-key - terminate it and launch again"
  elif [ "$ssh_world" = true ]; then
    no "4.2 amigos-reader's security group has SSH open to the whole internet - change the source to My IP (${MY_IP:-your IP}/32)"
  elif [[ "$profile" != */ec2-s3-reader ]]; then
    no "4.2 attach ec2-s3-reader to amigos-reader (Actions → Security → Modify IAM role)"
  elif [ "$itag" != "$TAG_VALUE" ]; then
    no "4.2 tag amigos-reader with course = aws-essentials (Tags tab → Manage tags)"
  else
    ok "4.2 instance 'amigos-reader' runs with the role ec2-s3-reader"
  fi
fi

key="$(aws ec2 describe-key-pairs --key-names amigos-key --include-public-key --query 'KeyPairs[0].PublicKey' --output text 2>/dev/null)"
KEY_FP=""
[ -n "$key" ] && [ "$key" != None ] && KEY_FP="$(ssh-keygen -lf /dev/stdin <<<"$key" 2>/dev/null | awk '{print $2}')"

# One look from inside the server. It prints connected=yes, the role it runs as, whether
# the role can read the files bucket and list the site bucket, and one fp= line per key
# that has logged in as ec2-user.
PROBE="echo connected=yes
echo \"arn=\$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)\"
aws s3api head-object --bucket $FILES --key notes/hello.txt >/dev/null 2>&1 && echo read=yes || echo read=no
aws s3api list-objects-v2 --bucket $SITE --max-items 1 >/dev/null 2>&1 && echo site=yes || echo site=no
aws s3api list-objects-v2 --bucket $FILES --max-items 1 >/dev/null 2>&1 && echo list=yes || echo list=no
journalctl -u sshd --no-pager -o cat 2>/dev/null | grep 'Accepted publickey for ec2-user' | grep -o 'SHA256:[A-Za-z0-9+/]*' | sort -u | sed 's/^/fp=/'
true"
inside="" ssh_err=""
if [ "$STATE" = running ] && [ -n "$PUBLIC_IP" ]; then
  rm -f /tmp/probe /tmp/probe.pub
  ssh-keygen -q -t ed25519 -N '' -C aws-essentials-checker -f /tmp/probe >/dev/null 2>&1
  if aws ec2-instance-connect send-ssh-public-key --instance-id "$IID" --instance-os-user ec2-user \
       --ssh-public-key file:///tmp/probe.pub >/dev/null 2>/tmp/eic-err; then
    inside="$(ssh -i /tmp/probe -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
      "ec2-user@$PUBLIC_IP" 'sudo bash -s' <<<"$PROBE" 2>/tmp/ssh-err)"
    ssh_err="$(tr '\n' ' ' </tmp/ssh-err)"
  else
    ssh_err="instance connect: $(tr '\n' ' ' </tmp/eic-err)"
  fi
fi
field() { sed -n "s/^$1=//p" <<<"$inside" | head -1; }

if [ "$STATE" != running ]; then
  no "4.3 you logged in to amigos-reader over SSH - it must be running (4.2)"
elif [ -z "$PUBLIC_IP" ]; then
  no "4.3 amigos-reader has no public IP - launch it again with Auto-assign public IP: Enable"
elif [ "$(field connected)" != yes ]; then
  case "$ssh_err" in
    *"timed out"*|*"Connection refused"*|*"No route"*)
      no "4.3 SSH to $PUBLIC_IP times out from this machine - its security group must allow SSH from ${MY_IP:-your IP}/32" ;;
    *)
      no "4.3 the checker could not log in to amigos-reader over SSH: ${ssh_err:-no answer} - try again in a minute" ;;
  esac
elif [ -z "$KEY_FP" ]; then
  no "4.3 the key pair amigos-key is missing - create it as in section 02 (1.2), then launch amigos-reader with it"
elif grep -qx "fp=$KEY_FP" <<<"$inside"; then
  ok "4.3 you logged in to amigos-reader over SSH with amigos-key"
else
  no "4.3 no SSH login with amigos-key on amigos-reader yet - add Host amigos-reader to ~/.ssh/config and run: ssh amigos-reader"
fi

arn="$(field arn)"
if [ "$(field connected)" != yes ]; then
  no "4.4 on the server, the role reads the files bucket and nothing else - the checker needs SSH to amigos-reader first (4.3)"
elif [[ "$arn" != *":assumed-role/ec2-s3-reader/"* ]]; then
  no "4.4 the server has no role credentials (it is: ${arn:-nobody}) - attach ec2-s3-reader (Actions → Security → Modify IAM role)"
elif [ "$(field read)" != yes ]; then
  no "4.4 the server can't read $FILES/notes/hello.txt - is the file there (1.3), and does S3ReadOnlyCourse allow it (3.4)?"
elif [ "$(field list)" != yes ]; then
  no "4.4 the server can't list $FILES - S3ReadOnlyCourse needs s3:ListBucket on arn:aws:s3:::$FILES (3.4)"
elif [ "$(field site)" = yes ]; then
  no "4.4 the server can still list $SITE - narrow S3ReadOnlyCourse to the files bucket (3.4)"
else
  ok "4.4 on the server, the role reads the files bucket and nothing else"
fi

score
[[ $fail -eq 0 ]] && echo "🎉 One bucket locked down, one public on purpose, old versions cleaned up, and a server that reads exactly one bucket - with a role, no keys."

# ---- what is billing right now --------------------------------------------------
running="$(jq -r '[.[] | select(.State.Name == "running" or .State.Name == "pending") | .InstanceId] | join(" ")' <<<"$inst")"
stopped="$(jq -r '[.[] | select(.State.Name == "stopped" or .State.Name == "stopping") | .InstanceId] | join(" ")' <<<"$inst")"
if [ -n "$running$stopped" ]; then
  echo
  echo "⚠️  Billed by the hour in us-east-1 right now:"
  [ -n "$running" ] && echo "   - running amigos-reader: $running  (server + public IP, about \$0.015/hour)"
  [ -n "$stopped" ] && echo "   - stopped amigos-reader: $stopped  (no server charge, but its disk still is)"
  echo "   When you are done: ${LAUNCHER:-./course.sh} stop 04-s3"
fi
exit 0
