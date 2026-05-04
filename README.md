# BTCMS Infrastructure

`betsoft.dev` altyapı yönetimi — Caddy config, kurulum scriptleri, Cloudflare DNS otomasyonu.

## Repo amacı

Bu repo **fiziksel sunucu/network setup'ını** tutar. Uygulama kodu yok — sadece:
- Caddy konfigürasyonu (subdomain → service routing)
- Sunucu kurulum bash scriptleri (apt, php, mysql, caddy, node)
- Cloudflare DNS yönetim helper'ları
- Network planı + secret deploy yönergeleri

Public yapılabilir (sırlar `secrets/` altında ve `.gitignore`'da, repo'ya gitmez).

## Sunucu envanteri

| Sunucu | IP (private) | IP (public) | Görev |
|--|--|--|--|
| **vds-web** | `10.10.10.10` | (TODO) | Caddy + PHP-FPM + MySQL + admin paneli |
| **vds-scrape** | `10.10.10.20` | (TODO) | Puppeteer servisleri |
| **vds-bots** | `10.10.10.30` | (TODO) | Node/Python bot'lar |
| (eski) `46.224.92.65` | — | mevcut | **Mail server (dokunulmaz)** |

## Subdomain planı

Tüm subdomain'ler Cloudflare proxy arkasında (orange cloud), sertifika **Cloudflare Origin Cert** (15 yıl geçerli, `caddy/cf-origin.{pem,key}`).

| Subdomain | Hedef | Servis |
|--|--|--|
| `admin.betsoft.dev` | vds-web:443 | btcms-admin (CI4) |
| `bonus.betsoft.dev` | vds-web:443 | btcms-admin (public bonus-talep) |
| `btk.betsoft.dev` | vds-web:443 → vds-bots:8001 | btcms-btk-autoquery |
| `rapor.betsoft.dev` | vds-web:443 → vds-scrape:3001 | btcms-dagur-rapor |
| `vpn.betsoft.dev` | vds-web:443 → ? | btcms-vpn (eklenecek) |
| `lookup.betsoft.dev` | vds-web:443 → vds-scrape:8767 | btcms-dagur-lookup (iç kullanım) |

## İlk kurulum (sıralı)

```bash
# Lokal: secrets'ı doldur
cp .env.example .env
nano .env  # Cloudflare token + VDS IP'leri

# 1. Her VDS için (vds-web, vds-scrape, vds-bots):
scp install/01-bootstrap.sh root@<vds-ip>:/tmp/
ssh root@<vds-ip> "bash /tmp/01-bootstrap.sh"

# 2. vds-web özel kurulum (PHP, MySQL, Caddy):
scp install/02-install-php.sh install/03-install-mysql.sh install/04-install-caddy.sh root@<vds-web-ip>:/tmp/
ssh root@<vds-web-ip> "bash /tmp/02-install-php.sh && bash /tmp/03-install-mysql.sh && bash /tmp/04-install-caddy.sh"

# 3. vds-scrape ve vds-bots: Node + PM2
ssh root@<vds-scrape-ip> "bash -s" < install/05-install-node.sh
ssh root@<vds-bots-ip>   "bash -s" < install/05-install-node.sh

# 4. Cloudflare Origin Cert deploy (vds-web'de)
bash install/06-deploy-cloudflare-cert.sh

# 5. DNS kayıtlarını ekle (lokalden)
bash dns/cf-add-record.sh A admin <vds-web-public-ip>
bash dns/cf-add-record.sh A btk   <vds-web-public-ip>
# ...
```

## Klasör yapısı

```
caddy/
├── Caddyfile               (tüm subdomain'ler — tek dosya)
└── snippets/               (php-fpm, reverse-proxy şablonları)
install/
├── 01-bootstrap.sh         (her VDS — base)
├── 02-install-php.sh       (vds-web)
├── 03-install-mysql.sh     (vds-web)
├── 04-install-caddy.sh     (vds-web)
├── 05-install-node.sh      (vds-scrape, vds-bots)
└── 06-deploy-cloudflare-cert.sh
dns/
├── cf-add-record.sh
├── cf-list-records.sh
└── cf-delete-record.sh
network/
└── README.md               (10.10.10.0/24 plan, ESXi vSwitch ayarı)
secrets/                    (gitignore'da; cf token, db password, vb.)
scripts/
└── (operasyonel scripts ileride)
```

## Secrets yönetimi

`secrets/` klasörü `.gitignore`'da. Her sunucuya manuel deploy:

```bash
# Lokal: secrets'ı vds-web'e kopyala
scp secrets/cf-origin.{pem,key} root@<vds-web>:/etc/caddy/
ssh root@<vds-web> "chown caddy:caddy /etc/caddy/cf-origin.* && chmod 600 /etc/caddy/cf-origin.key"
```

## Lisans

Özel/proprietary. Public yapılabilir ama **secrets dosyaları repo'ya konulmaz**.
