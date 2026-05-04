#!/usr/bin/env bash
# 03-install-mysql.sh — vds-web için MySQL 8 + secure
set -euo pipefail

echo "==> MySQL 8 kurulumu"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq mysql-server

systemctl enable --now mysql

echo "==> mysql_secure_installation otomasyonu"
ROOT_PW="${MYSQL_ROOT_PASSWORD:-$(openssl rand -base64 24)}"
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${ROOT_PW}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

echo "==> Root parola dosyaya yazılıyor (sadece root okur)"
mkdir -p /root/.mysql
echo "[client]" > /root/.mysql/root.cnf
echo "user=root" >> /root/.mysql/root.cnf
echo "password=${ROOT_PW}" >> /root/.mysql/root.cnf
chmod 600 /root/.mysql/root.cnf

echo "==> btcms DB + user oluştur"
BTCMS_DB="btcms"
BTCMS_USER="btcms_user"
BTCMS_PW="${BTCMS_DB_PASSWORD:-$(openssl rand -base64 24)}"
mysql --defaults-file=/root/.mysql/root.cnf <<EOF
CREATE DATABASE IF NOT EXISTS \`${BTCMS_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${BTCMS_USER}'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${BTCMS_PW}';
GRANT ALL PRIVILEGES ON \`${BTCMS_DB}\`.* TO '${BTCMS_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "==> btcms credential'ları kaydediliyor"
echo "DB_HOST=127.0.0.1"           > /root/.mysql/btcms.env
echo "DB_NAME=${BTCMS_DB}"         >> /root/.mysql/btcms.env
echo "DB_USER=${BTCMS_USER}"       >> /root/.mysql/btcms.env
echo "DB_PASSWORD=${BTCMS_PW}"     >> /root/.mysql/btcms.env
chmod 600 /root/.mysql/btcms.env

echo
echo "✓ MySQL kurulumu tamam."
echo "  root parola : /root/.mysql/root.cnf"
echo "  btcms env   : /root/.mysql/btcms.env"
echo
echo "Sıradaki: btcms-admin .env dosyasına /root/.mysql/btcms.env içeriğini koy."
