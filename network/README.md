# Network Planı

## Topology

```
                        ┌─────────────────────────┐
                        │  Cloudflare (orange ☁)  │
                        │  *.betsoft.dev → vds-web│
                        └────────────┬────────────┘
                                     │ HTTPS (Origin Cert)
                                     │
                  ┌──────────────────▼──────────────────┐
                  │           ESXi host                 │
                  │  44 vCPU, 256 GB RAM, 1 TB SSD     │
                  │                                     │
                  │  ┌──────────────────────────────┐  │
                  │  │  vSwitch-Public (uplink)     │  │
                  │  └──────────┬───────────────────┘  │
                  │             │                       │
                  │   ┌─────────▼──────────┐           │
                  │   │  vds-web           │           │
                  │   │  pub: <PUB-IP>     │           │
                  │   │  prv: 10.10.10.10  │           │
                  │   └─────┬──────────────┘           │
                  │         │                           │
                  │  ┌──────▼─────────────────────┐   │
                  │  │  vSwitch-Internal (10.10/24)│  │
                  │  └──────┬─────────────┬───────┘   │
                  │         │             │            │
                  │  ┌──────▼──────┐ ┌───▼──────────┐ │
                  │  │ vds-scrape  │ │ vds-bots     │ │
                  │  │ 10.10.10.20 │ │ 10.10.10.30  │ │
                  │  │ (puppeteer) │ │ (Node + Py)  │ │
                  │  └─────────────┘ └──────────────┘ │
                  └─────────────────────────────────────┘
```

## IP plan

| VDS | Private IP | Public IP | Subnet |
|--|--|--|--|
| vds-web | 10.10.10.10 | (TODO) | 10.10.10.0/24 |
| vds-scrape | 10.10.10.20 | (puppeteer çıkışı için public ALABILIR) | 10.10.10.0/24 |
| vds-bots | 10.10.10.30 | (Telegram/SMS API çıkışı için public ALABILIR) | 10.10.10.0/24 |

## ESXi network setup

1. **vSwitch-Internal** oluştur (uplink yok = izole):
   - Networking → Virtual switches → Add standard virtual switch
   - Name: `vSwitch-Internal`, Uplink: yok, MTU: 1500

2. **Port group** ekle:
   - Networking → Port groups → Add port group
   - Name: `pg-internal`, Virtual switch: `vSwitch-Internal`, VLAN: 0

3. Her VM'in **2 NIC**'i olur:
   - `ens160` (eth0) — public (`VM Network`, default vSwitch)
   - `ens192` (eth1) — internal (`pg-internal`, vSwitch-Internal)

4. Internal IP atama (Ubuntu 24.04 netplan):
   ```yaml
   # /etc/netplan/02-internal.yaml (vds-web örneği)
   network:
     version: 2
     ethernets:
       ens192:
         addresses: [10.10.10.10/24]
         dhcp4: false
   ```
   `netplan apply`

## Trafiği bölme stratejisi

- **Cloudflare → vds-web public**: tüm HTTPS trafiği
- **vds-web → diğerleri**: Caddy reverse_proxy üstünden 10.10.10.x:port
- **scrape/bots → internet**: kendi public IP'leri ile çıkar (puppeteer dışarı erişir)
- **scrape/bots → DB**: vds-web'in 10.10.10.10:3306'sına bağlanır (MySQL bind-address: 0.0.0.0 + ufw 10.10.10.0/24)

## Firewall (ufw, her VDS)

```bash
# Hepsinde
ufw default deny incoming
ufw allow 22/tcp                          # SSH

# vds-web ek
ufw allow 80/tcp                          # HTTP (Cloudflare → 80, redirect)
ufw allow 443/tcp                         # HTTPS
ufw allow from 10.10.10.0/24 to any port 3306  # MySQL sadece iç ağ

# vds-scrape ek (servis port'ları sadece iç ağ)
ufw allow from 10.10.10.0/24 to any port 8767  # dagur-lookup
ufw allow from 10.10.10.0/24 to any port 8766  # ct-trader
ufw allow from 10.10.10.0/24 to any port 3001  # dagur-rapor

# vds-bots ek
ufw allow from 10.10.10.0/24 to any port 8001  # btk-autoquery
ufw allow from 10.10.10.0/24 to any port 5000  # turnstile-proxy
```

Tüm public port'lar (22 + 80/443 vds-web'de) Cloudflare/SSH dışına açık değil.
