#!/usr/bin/env bash
# cf-list-records.sh — Mevcut DNS kayıtlarını listele
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ ! -f .env ]]; then echo "✗ .env yok"; exit 1; fi
# shellcheck disable=SC1091
source .env

curl -sS "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?per_page=100" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
| python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success"):
    print("✗ Hata:", data.get("errors"))
    sys.exit(1)
records = data.get("result", [])
print(f"Toplam {len(records)} kayıt:\n")
print(f"{\"TYPE\":<6} {\"NAME\":<40} {\"CONTENT\":<50} PROXIED")
print("-" * 110)
for r in sorted(records, key=lambda x: (x.get("type",""), x.get("name",""))):
    name = r.get("name", "")
    content = (r.get("content") or "")[:48]
    proxied = "☁" if r.get("proxied") else "·"
    print(f"{r.get(\"type\",\"\"):<6} {name:<40} {content:<50} {proxied}")
'
