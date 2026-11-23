#!/usr/bin/env bash
# Grades "01 - Account Safety" against the student's real AWS account.
#
# Runs inside the AWS CLI container, after lib/aws.sh (which provides ok/no/score
# and the signed-in check). Read-only: nothing here changes the account.

require_login \
  "1.2 the checker is signed in to your AWS account" \
  "1.3 the root user has MFA" \
  "2.1 a \$5 monthly cost budget 'amigoscode-budget'" \
  "2.2 'amigoscode-budget' emails you at 80% of actual spend" \
  "2.3 a zero spend budget" \
  "3.2 an account alias"

echo "Tier 1 - Create and secure your account"

# 1.1 is a drill, but the plan is worth showing: it decides whether mistakes cost money.
plan="$(aws freetier get-account-plan-state \
  --query '[accountPlanType, accountPlanRemainingCredits.amount, accountPlanExpirationDate]' \
  --output text 2>/dev/null || true)"
read -r plan_type credits ends <<<"$plan"
# Accounts created before the Free plan existed (July 2025) have no plan at all:
# the API answers ResourceNotFoundException and we get nothing back.
case "${plan_type:-}" in
  FREE) note "Free plan - \$${credits:-?} credits left, ends ${ends%%T*}" ;;
  *)    note "This account is not on the Free plan: anything you leave running is billed to your card."
        note "Delete what you build at the end of every section." ;;
esac

case "$CALLER_ARN" in
  *:root) who="the root user" ;;
  *)      who="${CALLER_ARN##*/}" ;;
esac
ok "1.2 the checker is signed in to account $ACCOUNT as $who"

mfa="$(aws iam get-account-summary --query 'SummaryMap.AccountMFAEnabled' --output text 2>/dev/null || true)"
if [ "$mfa" = "1" ]; then
  ok "1.3 the root user has MFA"
elif [ -z "$mfa" ]; then
  no "1.3 could not read the account summary - sign the checker in as root or an admin user"
else
  no "1.3 turn on MFA for the root user (account menu → Security credentials → Assign MFA device)"
fi

echo "Tier 2 - Guard the bill"

budgets="$(aws budgets describe-budgets --account-id "$ACCOUNT" --output json 2>/dev/null || true)"
[ -n "$budgets" ] || budgets='{"Budgets":[]}'

main="$(jq -r '(.Budgets // [])[] | select(.BudgetName == "amigoscode-budget")
  | [.BudgetType, .TimeUnit, .BudgetLimit.Amount, .BudgetLimit.Unit] | @tsv' <<<"$budgets")"
if [ -z "$main" ]; then
  no "2.1 create a monthly cost budget named 'amigoscode-budget' with an amount of \$5"
else
  read -r btype bunit bamount bcurrency <<<"$main"
  if [ "$btype" != "COST" ]; then
    no "2.1 'amigoscode-budget' must be a COST budget (it is $btype)"
  elif [ "$bunit" != "MONTHLY" ]; then
    no "2.1 'amigoscode-budget' must reset monthly (it is $bunit)"
  elif [ "$bcurrency" != "USD" ] || ! awk -v a="$bamount" 'BEGIN { exit !(a == 5) }'; then
    no "2.1 set the 'amigoscode-budget' amount to \$5 (it is $bamount $bcurrency)"
  else
    ok "2.1 a \$5 monthly cost budget 'amigoscode-budget'"
  fi
fi

# 2.2: an alert on ACTUAL spend, as a percentage of the budget, at 100% or below
# (80% is asked; a template's 85% is fine too), with an email subscriber.
alert_ok=false
if [ -n "$main" ]; then
  notes="$(aws budgets describe-notifications-for-budget --account-id "$ACCOUNT" \
    --budget-name amigoscode-budget --output json 2>/dev/null || echo '{}')"
  while IFS=$'\t' read -r ntype op threshold ttype; do
    [ -n "$ntype" ] || continue
    subs="$(aws budgets describe-subscribers-for-notification --account-id "$ACCOUNT" \
      --budget-name amigoscode-budget \
      --notification "NotificationType=$ntype,ComparisonOperator=$op,Threshold=$threshold,ThresholdType=$ttype" \
      --query "Subscribers[?SubscriptionType=='EMAIL'] | length(@)" --output text 2>/dev/null || echo 0)"
    [ "${subs:-0}" -gt 0 ] 2>/dev/null && alert_ok=true
  # AWS leaves ThresholdType out of the response when it is PERCENTAGE (the default).
  done < <(jq -r '(.Notifications // [])[] | .ThresholdType = (.ThresholdType // "PERCENTAGE")
      | select(.NotificationType == "ACTUAL" and .ThresholdType == "PERCENTAGE" and .Threshold <= 100)
      | [.NotificationType, .ComparisonOperator, .Threshold, .ThresholdType] | @tsv' <<<"$notes")
fi
if $alert_ok; then
  ok "2.2 'amigoscode-budget' emails you at 80% of actual spend"
else
  no "2.2 add an alert to 'amigoscode-budget': actual spend, 80% of the budget, sent to your email"
fi

# 2.3: the Zero spend budget template - any other cost budget of \$1 or less.
zero="$(jq -r '[(.Budgets // [])[] | select(.BudgetName != "amigoscode-budget"
  and .BudgetType == "COST" and ((.BudgetLimit.Amount // "999") | tonumber) <= 1)] | length' <<<"$budgets")"
if [ "${zero:-0}" -gt 0 ]; then
  ok "2.3 a zero spend budget"
else
  no "2.3 create a budget from the 'Zero spend budget' template, named 'amigoscode-zero-spend'"
fi

echo "Tier 3 - Find your way around"

alias="$(aws iam list-account-aliases --query 'AccountAliases[0]' --output text 2>/dev/null || true)"
if [ -n "$alias" ] && [ "$alias" != "None" ]; then
  ok "3.2 account alias '$alias' (sign in at https://$alias.signin.aws.amazon.com/console)"
else
  no "3.2 create an account alias (IAM → Dashboard → AWS Account → Account Alias → Create)"
fi

score
[[ $fail -eq 0 ]] && echo "🎉 Your account is locked down and the bill has alarms on it."
exit 0
