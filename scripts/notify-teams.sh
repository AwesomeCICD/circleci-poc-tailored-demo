#!/usr/bin/env bash
# Post an approval request to a Teams Workflows webhook.
# TEAMS_WEBHOOK_URL is a project environment variable. Unset means skip.
# A failed post must not fail the job.
set -u

if [ -z "${TEAMS_WEBHOOK_URL:-}" ]; then
  echo "Teams notification skipped"
  exit 0
fi

environment="${NOTIFY_ENVIRONMENT:?NOTIFY_ENVIRONMENT is required}"
version="${NOTIFY_VERSION:?NOTIFY_VERSION is required}"
link="https://app.circleci.com/pipelines/workflows/${CIRCLE_WORKFLOW_ID:-local}"

payload=$(cat <<EOF
{
  "type": "message",
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "contentUrl": null,
      "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.2",
        "body": [
          {
            "type": "TextBlock",
            "text": "Approval needed for ${environment}",
            "weight": "Bolder",
            "wrap": true
          },
          {
            "type": "TextBlock",
            "text": "Version ${version} is waiting. Open the workflow to approve: ${link}",
            "wrap": true
          }
        ]
      }
    }
  ]
}
EOF
)

if [ "${NOTIFY_PRINT_ONLY:-}" = "1" ]; then
  printf '%s\n' "$payload"
  exit 0
fi

body_file="$(mktemp)"
set +e
http_code="$(curl -sS -o "$body_file" -w "%{http_code}" --max-time 15 \
  -X POST -H "Content-Type: application/json" \
  --data "$payload" \
  "$TEAMS_WEBHOOK_URL")"
curl_status=$?
set -e
rm -f "$body_file"

if [ "$curl_status" -ne 0 ] || [ -z "$http_code" ]; then
  echo "Warning: Teams notification failed (HTTP ${http_code:-none}, curl exit ${curl_status})"
  exit 0
fi

case "$http_code" in
  2*) exit 0 ;;
  *)
    echo "Warning: Teams notification failed (HTTP ${http_code})"
    exit 0
    ;;
esac
