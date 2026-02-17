#!/usr/bin/env bash
set -euo pipefail

echo "▶️  STARTING send_to_notion_image.sh"

# Load local env file if present (do not commit)
ENV_FILE="$HOME/.config/preview-to-notion/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

echo "▶️  READ env file"

# --- CONFIG ---
: "${NOTION_TOKEN:?Set NOTION_TOKEN (Notion internal integration token)}"
: "${NOTES_DB_ID:?Set NOTES_DB_ID (target Notion database id)}"

PROP_TITLE="${PROP_TITLE:-Name}"
PROP_TYPE="${PROP_TYPE:-Type}"
TYPE_VALUE="${TYPE_VALUE:-Image}"
NOTION_VERSION="${NOTION_VERSION:-2025-09-03}"

die() { echo "❌ $*" >&2; exit 1; }
command -v jq >/dev/null || die "jq not found. Install: brew install jq"

[[ $# -ge 1 ]] || die "Usage: send_to_notion_image.sh /path/to/image1 [image2 ...]"

infer_mime_from_ext() {
  local fn="$1" ext="${fn##*.}"
  ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"
  case "$ext" in
    jpg|jpeg) echo "image/jpeg" ;;
    png)      echo "image/png" ;;
    heic)     echo "image/heic" ;;
    gif)      echo "image/gif" ;;
    webp)     echo "image/webp" ;;
    tif|tiff) echo "image/tiff" ;;
    bmp)      echo "image/bmp" ;;
    *)        echo "application/octet-stream" ;;
  esac
}

for img in "$@"; do
  [[ -f "$img" ]] || die "Not a file: $img"

  filename="$(basename "$img")"
  default_title="${filename%.*}"

  echo "🖼️  File: $filename"
  echo "📝 Prompting for title…"

  page_title="$(osascript -e 'tell application "System Events"
    activate
    try
      set d to display dialog "Notion page title:" default answer "'"$default_title"'" with title "Send Image to Notion" buttons {"Cancel","OK"} default button "OK"
      return text returned of d
    on error number -128
      return ""
    end try
  end tell')"

  [[ -n "$page_title" ]] || { echo "Cancelled for: $filename"; continue; }

  mime="$(/usr/bin/file -b --mime-type "$img" 2>/dev/null || true)"
  if [[ -z "$mime" || "$mime" == *"cannot open"* ]]; then
    mime="$(infer_mime_from_ext "$filename")"
  fi
  echo "📦 MIME: $mime"

  upload_obj="$(
    curl -sS --request POST \
      --url "https://api.notion.com/v1/file_uploads" \
      -H "Authorization: Bearer $NOTION_TOKEN" \
      -H "Content-Type: application/json" \
      -H "Notion-Version: $NOTION_VERSION" \
      --data "$(jq -n --arg fn "$filename" --arg ct "$mime" '{mode:"single_part", filename:$fn, content_type:$ct}')"
  )"

  upload_id="$(echo "$upload_obj" | jq -r '.id')"
  upload_url="$(echo "$upload_obj" | jq -r '.upload_url')"
  [[ "$upload_id" != "null" && -n "$upload_id" ]] || die "Failed to create upload object: $upload_obj"
  [[ "$upload_url" != "null" && -n "$upload_url" ]] || die "Missing upload_url: $upload_obj"

  curl -sS --request POST \
    --url "$upload_url" \
    -H "Authorization: Bearer $NOTION_TOKEN" \
    -H "Notion-Version: $NOTION_VERSION" \
    -F "file=@${img}" >/dev/null

  page_resp="$(
    curl -sS --request POST \
      --url "https://api.notion.com/v1/pages" \
      -H "Authorization: Bearer $NOTION_TOKEN" \
      -H "Content-Type: application/json" \
      -H "Notion-Version: $NOTION_VERSION" \
      --data "$(jq -n \
        --arg db "$NOTES_DB_ID" \
        --arg titleProp "$PROP_TITLE" \
        --arg typeProp "$PROP_TYPE" \
        --arg title "$page_title" \
        --arg typeVal "$TYPE_VALUE" \
        '{
          parent: { database_id: $db },
          properties: {
            ($titleProp): { title: [ { text: { content: $title } } ] },
            ($typeProp): { select: { name: $typeVal } }
          }
        }')"
  )"

  page_id="$(echo "$page_resp" | jq -r '.id')"
  [[ "$page_id" != "null" && -n "$page_id" ]] || die "Failed to create page: $page_resp"

  curl -sS --request PATCH \
    --url "https://api.notion.com/v1/blocks/${page_id}/children" \
    -H "Authorization: Bearer $NOTION_TOKEN" \
    -H "Content-Type: application/json" \
    -H "Notion-Version: $NOTION_VERSION" \
    --data "$(jq -n --arg upid "$upload_id" '{
      children: [
        { type: "image",
          image: { caption: [], type: "file_upload", file_upload: { id: $upid } }
        }
      ]
    }')" >/dev/null

  echo "✅ Sent: $filename → \"$page_title\""
done
