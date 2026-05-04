#!/usr/bin/env bash
# 04-install-caddy.sh — vds-web için Caddy 2 (apt repo)
set -euo pipefail

echo "==> Caddy 2 (resmi apt repo)"
apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
apt-get update -qq
apt-get install -y -qq caddy

systemctl enable caddy

echo "==> /etc/caddy yapısı"
mkdir -p /etc/caddy/sites
chown -R caddy:caddy /etc/caddy

echo "==> Cloudflare Origin Certificate yer ayır"
echo "  Sertifikayı /etc/caddy/cf-origin.pem ve /etc/caddy/cf-origin.key olarak yükle:"
echo "    scp secrets/cf-origin.pem root@<vds-web>:/etc/caddy/"
echo "    scp secrets/cf-origin.key root@<vds-web>:/etc/caddy/"
echo "  Sonra: chown caddy:caddy /etc/caddy/cf-origin.* && chmod 600 /etc/caddy/cf-origin.key"

echo
echo "==> Örnek Caddyfile yerleştir (gerçek deploy: btcms-infra/caddy/Caddyfile push edilir)"
if [[ ! -f /etc/caddy/Caddyfile.original ]]; then
    cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.original
fi

cat > /etc/caddy/Caddyfile <<'EOF'
# Bu placeholder. Gerçek config btcms-infra/caddy/Caddyfile'dan deploy edilir.
# scp btcms-infra/caddy/Caddyfile root@<vds-web>:/etc/caddy/
# systemctl reload caddy

:80 {
    respond "BTCMS — Caddy çalışıyor. Henüz site config yüklenmedi."
}
EOF

caddy validate --config /etc/caddy/Caddyfile
systemctl restart caddy

echo
echo "✓ Caddy kurulumu tamam."
echo "  status   : $(systemctl is-active caddy)"
echo "  config   : /etc/caddy/Caddyfile"
echo "  binary   : $(which caddy)"
caddy version
