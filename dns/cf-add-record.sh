#!/usr/bin/env bash
# cf-add-record.sh — Cloudflare'e DNS kaydı ekle (idempotent: varsa update)
# Kullanım:
#   bash dns/cf-add-record.sh A admin 1.2.3.4 [proxied]
#   bash dns/cf-add-record.sh CNAME alias other.betsoft.dev
#   bash dns/cf-add-record.sh TXT _acme txt-content
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ ! -f .env ]]; then echo "✗ .env yok"; exit 1; fi
# shellcheck disable=SC1091
source .env

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]] || [[ -z "${CLOUDFLARE_ZONE_ID:-}" ]]; then
    echo "✗ .env'de CLOUDFLARE_API_TOKEN veya CLOUDFLARE_ZONE_ID boş"
    exit 1
fi

TYPE="${1:-}"
NAME="${2:-}"
CONTENT="${3:-}"
PROXIED_FLAG="${4:-proxied}"

if [[ -z "$TYPE" || -z "$NAME" || -z "$CONTENT" ]]; then
    echo "Kullanım: $0 <TYPE> <NAME> <CONTENT> [proxied|not-proxied]"
    echo "  Örnek:  $0 A admin 78.46.107.241 proxied"
    echo "  Örnek:  $0 CNAME api admin.betsoft.dev not-proxied"
    exit 1
fi

PROXIED=true
[[ "$PROXIED_FLAG" == "not-proxied" ]] && PROXIED=false
# CNAME/TXT/MX gibi tipler genelde proxy edilmez
[[ "$TYPE" == "TXT" || "$TYPE" == "MX" || "$TYPE" == "NS" ]] && PROXIED=false

FQDN="${NAME}.${CLOUDFLARE_ZONE_NAME}"
[[ "$NAME" == "@" || "$NAME" == "$CLOUDFLARE_ZONE_NAME" ]] && FQDN="$CLOUDFLARE_ZONE_NAME"

API="https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records"
AUTH=(-H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" -H "Content-Type: application/json")

# Var mı kontrol — varsa update, yoksa create
EXISTING_ID=$(curl -sS "${API}?type=${TYPE}&name=${FQDN}" "${AUTH[@]}" | grep -oE '"id":"[a-f0-9]+"' | head -1 | cut -d'"' -f4)

PAYLOAD=$(printf '{"type":"%s","name":"%s","content":"%s","ttl":1,"proxied":%s}' \
    "$TYPE" "$FQDN" "$CONTENT" "$PROXIED")

if [[ -n "$EXISTING_ID" ]]; then
    echo "→ Update: $TYPE $FQDN → $CONTENT (proxied=$PROXIED, id=$EXISTING_ID)"
    RESP=$(curl -sS -X PUT "${API}/${EXISTING_ID}" "${AUTH[@]}" --data "$PAYLOAD")
else
    echo "→ Create: $TYPE $FQDN → $CONTENT (proxied=$PROXIED)"
    RESP=$(curl -sS -X POST "${API}" "${AUTH[@]}" --data "$PAYLOAD")
fi

SUCCESS=$(echo "$RESP" | grep -oE '"success":(true|false)' | head -1 | cut -d':' -f2)
if [[ "$SUCCESS" == "true" ]]; then
    REC_ID=$(echo "$RESP" | grep -oE '"id":"[a-f0-9]+"' | head -1 | cut -d'"' -f4)
    echo "  ✓ OK (id: $REC_ID)"
else
    echo "  ✗ Hata:"
    echo "$RESP" | head -c 400
    echo
    exit 1
fi
