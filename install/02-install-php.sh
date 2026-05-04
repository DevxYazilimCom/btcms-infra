#!/usr/bin/env bash
# 02-install-php.sh — vds-web için PHP 8.3 + extensions + composer
set -euo pipefail

echo "==> PHP 8.3 PPA (Ondrej)"
add-apt-repository -y ppa:ondrej/php
apt-get update -qq

echo "==> PHP 8.3 + ext'ler"
apt-get install -y -qq \
    php8.3-fpm php8.3-cli \
    php8.3-mysql php8.3-mbstring php8.3-xml php8.3-curl \
    php8.3-zip php8.3-intl php8.3-bcmath php8.3-gd \
    php8.3-redis php8.3-opcache php8.3-readline

echo "==> php.ini tuning (CMS workload için)"
PHP_INI=/etc/php/8.3/fpm/php.ini
sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$PHP_INI"
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 50M/' "$PHP_INI"
sed -i 's/^post_max_size = .*/post_max_size = 50M/' "$PHP_INI"
sed -i 's/^max_execution_time = .*/max_execution_time = 60/' "$PHP_INI"
sed -i 's/;date.timezone =/date.timezone = Europe\/Istanbul/' "$PHP_INI"

# Opcache aktif (production performans)
cat > /etc/php/8.3/fpm/conf.d/99-opcache.ini <<'EOF'
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=1
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF

echo "==> php-fpm pool: pm.max_children = 20 (eski memory: 5→20 boost)"
POOL=/etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/^pm.max_children = .*/pm.max_children = 20/' "$POOL"
sed -i 's/^pm.start_servers = .*/pm.start_servers = 4/' "$POOL"
sed -i 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 2/' "$POOL"
sed -i 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 6/' "$POOL"

systemctl enable --now php8.3-fpm
systemctl restart php8.3-fpm

echo "==> Composer 2"
EXPECTED_CHECKSUM="$(curl -s https://composer.github.io/installer.sig)"
curl -sSL -o /tmp/composer-setup.php https://getcomposer.org/installer
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
if [[ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]]; then
    echo "  ✗ Composer installer checksum YANLIŞ — abort"
    rm /tmp/composer-setup.php
    exit 1
fi
php /tmp/composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
rm /tmp/composer-setup.php

echo
echo "✓ PHP kurulumu tamam."
php -v | head -1
composer --version
echo "  php-fpm   : $(systemctl is-active php8.3-fpm)"
echo "  socket    : /run/php/php8.3-fpm.sock"
