#!/usr/bin/env bash
# 06-deploy-cloudflare-cert.sh — Cloudflare Origin Certificate'i vds-web'e kur
# Lokalden çalıştırılır. .env içinde VDS_WEB_PUBLIC_IP olmalı.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
    echo "✗ .env bulunamadı. cp .env.example .env yap, doldur."
    exit 1
fi
# shellcheck disable=SC1091
source .env

if [[ -z "${VDS_WEB_PUBLIC_IP:-}" ]]; then
    echo "✗ .env'de VDS_WEB_PUBLIC_IP boş."
    exit 1
fi

if [[ ! -f secrets/cf-origin.pem ]] || [[ ! -f secrets/cf-origin.key ]]; then
    echo "✗ secrets/cf-origin.pem ve secrets/cf-origin.key gerekli."
    echo "  Cloudflare → SSL/TLS → Origin Server → Create Certificate"
    echo "  Hostname: *.betsoft.dev, betsoft.dev — Validity: 15 years — Format: PEM"
    exit 1
fi

echo "==> Origin Cert vds-web'e kopyalanıyor (root@${VDS_WEB_PUBLIC_IP})"
scp -i "${SSH_KEY/\~/$HOME}" \
    secrets/cf-origin.pem secrets/cf-origin.key \
    "${SSH_USER}@${VDS_WEB_PUBLIC_IP}:/etc/caddy/"

echo "==> İzinleri ayarla"
ssh -i "${SSH_KEY/\~/$HOME}" "${SSH_USER}@${VDS_WEB_PUBLIC_IP}" '
    chown caddy:caddy /etc/caddy/cf-origin.pem /etc/caddy/cf-origin.key
    chmod 600 /etc/caddy/cf-origin.key
    chmod 644 /etc/caddy/cf-origin.pem
    ls -la /etc/caddy/cf-origin.*
'

echo
echo "✓ Cert deploy tamam. Caddyfile içinde şu satırı kullan:"
echo "    tls /etc/caddy/cf-origin.pem /etc/caddy/cf-origin.key"
