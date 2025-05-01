set -euo pipefail

IMAGE_FULL="$1"
TAG="$2"
PER_PAGE=20
PAGE=1

IFS='/' read -r ORG IMAGE <<< "$IMAGE_FULL"
EXPECTED_URL="https://github.com/orgs/$ORG/packages/container/package/$IMAGE"

while :; do
  echo "Checking page $PAGE" >&2
  response=$(gh api -H "Accept: application/vnd.github+json" \
    "/orgs/$ORG/packages/container/$IMAGE/versions?per_page=$PER_PAGE&page=$PAGE")

  # Ensure response is an array before processing
  if echo "$response" | jq -e 'type != "array"' > /dev/null; then
    echo "::error::Unexpected API response: $(echo "$response" | jq -r '.message // "unknown error"')" >&2
    exit 1
  fi

  id=$(echo "$response" | jq -r --arg TAG "$TAG" --arg URL "$EXPECTED_URL" '
    .[] |
    select(
      (.package_html_url // "") == $URL and
      ((.metadata.container.tags // []) | index($TAG))
    ) | .id' | head -n1)

  if [[ -n "$id" ]]; then
    echo "image_id=$id"
    exit 0
  fi

  count=$(echo "$response" | jq 'length')
  if (( count < PER_PAGE )); then
    echo "::error::Tag '$TAG' not found for image '$IMAGE_FULL'" >&2
    exit 1
  fi

  ((PAGE++))
done
