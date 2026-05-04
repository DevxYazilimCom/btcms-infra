#!/usr/bin/env bash
# 05-install-node.sh — vds-scrape ve vds-bots için Node 20 + PM2 + Chrome (puppeteer)
set -euo pipefail

echo "==> Node 20 (NodeSource)"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -qq nodejs build-essential

echo "==> npm global config"
npm config set fund false
npm config set audit false
npm config set update-notifier false

echo "==> PM2 global"
npm install -g pm2
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true

echo "==> Google Chrome (puppeteer için — sadece scrape sunucularında)"
# WANT_CHROME=y env var ile bypass, yoksa sor
if [[ -z "${WANT_CHROME:-}" ]]; then
    read -rp "Bu sunucuda puppeteer çalışacak mı? (vds-scrape=evet, vds-bots=hayır) [y/N] " WANT_CHROME
fi
if [[ "${WANT_CHROME,,}" == "y" ]]; then
    wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    apt-get install -y -qq /tmp/chrome.deb
    rm /tmp/chrome.deb

    # Headless dependencies
    apt-get install -y -qq \
        fonts-liberation libasound2t64 libatk-bridge2.0-0 libatk1.0-0 \
        libcups2 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 \
        libwayland-client0 libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 \
        libxrandr2 xdg-utils

    google-chrome --version
fi

echo "==> PM2 startup (boot'ta otomatik)"
pm2 startup systemd -u root --hp /root | tail -1 | bash
pm2 save

echo
echo "✓ Node + PM2 kurulumu tamam."
node --version
pm2 --version
