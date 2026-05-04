#!/usr/bin/env bash
# cf-delete-record.sh — DNS kaydı sil
# Kullanım: bash dns/cf-delete-record.sh A admin
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ ! -f .env ]]; then echo "✗ .env yok"; exit 1; fi
# shellcheck disable=SC1091
source .env

TYPE="${1:-}"
NAME="${2:-}"

if [[ -z "$TYPE" || -z "$NAME" ]]; then
    echo "Kullanım: $0 <TYPE> <NAME>   (örn: $0 A admin)"
    exit 1
fi

FQDN="${NAME}.${CLOUDFLARE_ZONE_NAME}"
[[ "$NAME" == "@" || "$NAME" == "$CLOUDFLARE_ZONE_NAME" ]] && FQDN="$CLOUDFLARE_ZONE_NAME"

API="https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records"
AUTH=(-H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")

REC_ID=$(curl -sS "${API}?type=${TYPE}&name=${FQDN}" "${AUTH[@]}" | grep -oE '"id":"[a-f0-9]+"' | head -1 | cut -d'"' -f4)

if [[ -z "$REC_ID" ]]; then
    echo "→ Kayıt bulunamadı: $TYPE $FQDN"
    exit 0
fi

echo "→ Sil: $TYPE $FQDN (id: $REC_ID)"
curl -sS -X DELETE "${API}/${REC_ID}" "${AUTH[@]}" | head -c 200
echo
