# Secrets — git'e ASLA gitmez

Bu klasör hassas dosyalar için. `.gitignore` ile tüm içerik dışlandı (sadece bu README ve `.gitignore` repo'da).

## Hangi dosyalar buraya gelecek

| Dosya | Açıklama |
|--|--|
| `cf-origin.pem` | Cloudflare Origin Certificate (15 yıl, `*.betsoft.dev`) |
| `cf-origin.key` | Origin Cert private key |
| `mysql-root.cnf` | vds-web MySQL root parolası (kurulum sonrası `/root/.mysql/root.cnf`'den çekilir) |
| `btcms-db.env` | btcms uygulamasının DB credential'ları (`/root/.mysql/btcms.env`) |
| `id_ed25519_deploy` | Sunucu SSH private key (lokalde `~/.ssh/`'dan kopya) |

## Cloudflare Origin Cert nasıl alınır

1. Cloudflare → SSL/TLS → **Origin Server** → **Create Certificate**
2. Hostnames: `*.betsoft.dev, betsoft.dev`
3. Validity: **15 years**
4. Format: **PEM (default)**
5. **Generate** → ekrandaki:
   - "Origin Certificate" bloğunu `cf-origin.pem` olarak kaydet
   - "Private Key" bloğunu `cf-origin.key` olarak kaydet
6. Sayfa kapanmadan kopyala — bir daha gösterilmez

## vds-web'e deploy

```bash
bash install/06-deploy-cloudflare-cert.sh
```

(scp + chown + chmod otomatik)

## Yedekleme

Bu klasörü ayrı bir yere (encrypted USB, 1Password attachment, vb.) yedekle. Cert'i kaybedersen 15 yıl beklemek yerine yenisini Cloudflare'den ücretsiz oluşturursun ama sürpriz downtime yaşarsın.
