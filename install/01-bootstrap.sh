#!/usr/bin/env bash
# 01-bootstrap.sh — Tüm VDS'ler için temel kurulum (Ubuntu 24.04)
# Kullanım: bash 01-bootstrap.sh
set -euo pipefail

echo "==> apt update & upgrade"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get -y -qq upgrade

echo "==> Temel paketler"
apt-get install -y -qq \
    curl wget git unzip vim htop \
    ca-certificates gnupg lsb-release \
    ufw fail2ban \
    net-tools dnsutils \
    rsync software-properties-common \
    cron logrotate

echo "==> Hostname ayarı"
# HOSTNAME_IN env var ile gelir (otomasyon), yoksa interaktif sorar
if [[ -z "${HOSTNAME_IN:-}" ]]; then
    read -rp "Bu sunucunun hostname'i (örn. vds-web): " HOSTNAME_IN
fi
if [[ -n "$HOSTNAME_IN" ]]; then
    hostnamectl set-hostname "$HOSTNAME_IN"
    grep -q "127.0.1.1 $HOSTNAME_IN" /etc/hosts || echo "127.0.1.1 $HOSTNAME_IN" >> /etc/hosts
fi

echo "==> Saat dilimi: Europe/Istanbul"
timedatectl set-timezone Europe/Istanbul

echo "==> UFW firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
# Web sunucuya HTTP/S (sadece vds-web için, diğerlerinde gerek yok ama zarar vermez)
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
ufw status

echo "==> fail2ban (SSH brute-force koruma)"
systemctl enable --now fail2ban

echo "==> Swap (RAM > 4GB ise atla)"
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
if [[ "$RAM_GB" -lt 4 ]] && [[ ! -f /swapfile ]]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "  ✓ 2GB swap eklendi"
else
    echo "  ↪ swap atlandı (RAM=${RAM_GB}GB)"
fi

echo "==> Sistem performans tuning"
# File handle limit
cat > /etc/security/limits.d/99-performance.conf <<'EOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

# Sysctl temel
cat > /etc/sysctl.d/99-btcms.conf <<'EOF'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 10
EOF
sysctl -p /etc/sysctl.d/99-btcms.conf >/dev/null

echo
echo "✓ Bootstrap tamam."
echo "  hostname  : $(hostname)"
echo "  timezone  : $(timedatectl show -p Timezone --value)"
echo "  ufw       : $(ufw status | head -1)"
echo "  fail2ban  : $(systemctl is-active fail2ban)"
echo
echo "Sıradaki: VDS rolüne göre 02/03/04/05 scriptlerini çalıştır."
