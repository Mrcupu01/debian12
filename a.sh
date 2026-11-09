#!/usr/bin/env bash

# Debian BIND9 Automatic Setup
# License: GNU GPL v2.0

set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Jalankan dengan: sudo $0"
    exit 1
fi

echo "======================================"
echo "        DEBIAN BIND9 AUTO SETUP"
echo "======================================"

# 1. Detect network interface
IFACE=$(ip -o -4 addr show up scope global |
    awk '$2 != "lo" {print $2; exit}')

if [[ -z "$IFACE" ]]; then
    echo "Tidak menemukan interface dengan IPv4."
    exit 1
fi

echo
echo "[+] Interface terdeteksi: $IFACE"

read -rp "Gunakan interface ini? (Y/n): " ANSWER
if [[ "$ANSWER" =~ ^[Nn]$ ]]; then
    read -rp "Masukkan nama interface: " IFACE
fi

if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "Interface tidak ditemukan."
    exit 1
fi

# 2. Detect IPv4 and subnet
CIDR=$(ip -o -4 addr show dev "$IFACE" scope global |
    awk 'NR==1 {print $4}')

if [[ -z "$CIDR" ]]; then
    echo "Interface tidak memiliki IPv4."
    exit 1
fi

IP=${CIDR%/*}

SUBNET=$(python3 -c \
    "import ipaddress; print(ipaddress.ip_interface('$CIDR').network)")

echo "[+] IP       : $IP"
echo "[+] Subnet   : $SUBNET"

# 3. Domain configuration
echo
read -rp "Domain lokal [tkj.test]: " DOMAIN
DOMAIN=${DOMAIN:-tkj.test}

if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]] ||
    [[ "$DOMAIN" != *.* ]] ||
    [[ "$DOMAIN" == *..* ]]; then
    echo "Nama domain tidak valid."
    exit 1
fi

DOMAIN=${DOMAIN,,}

read -rp "Nama host [server]: " HOST
HOST=${HOST:-server}

if ! [[ "$HOST" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "Nama host tidak valid."
    exit 1
fi

HOST=${HOST,,}

echo
echo "========== KONFIGURASI =========="
echo "Interface : $IFACE"
echo "IP Server : $IP"
echo "Subnet    : $SUBNET"
echo "Domain    : $DOMAIN"
echo "Host      : $HOST.$DOMAIN"
echo "================================="

read -rp "Lanjut instalasi? (y/n): " CONFIRM
[[ "$CONFIRM" == "y" ]] || exit 0

# 4. Install packages
echo
echo "[+] Menginstal BIND9..."

apt-get update
apt-get install -y bind9 bind9-utils dnsutils

# 5. Backup existing configurations
BACKUP="/root/bind9-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cp -a /etc/bind/named.conf.options "$BACKUP/"
cp -a /etc/bind/named.conf.local "$BACKUP/"

if [[ -e /etc/bind/debian-custom-zones.conf ]]; then
    cp -a /etc/bind/debian-custom-zones.conf "$BACKUP/"
fi

if [[ -e "/etc/bind/db.$DOMAIN" ]]; then
    cp -a "/etc/bind/db.$DOMAIN" "$BACKUP/"
fi

echo "[+] Backup: $BACKUP"

# 6. Configure BIND options
cat > /etc/bind/named.conf.options <<EOF
acl "trusted" {
    localhost;
    $SUBNET;
};

options {
    directory "/var/cache/bind";

    listen-on port 53 {
        127.0.0.1;
        $IP;
    };

    listen-on-v6 { none; };

    allow-query { trusted; };

    recursion yes;
    allow-recursion { trusted; };
    allow-transfer { none; };

    forwarders {
        1.1.1.1;
        8.8.8.8;
    };

    dnssec-validation auto;
};
EOF

# 7. Configure DNS zone
cat > /etc/bind/debian-custom-zones.conf <<EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
    allow-transfer { none; };
};
EOF

# Add include only once
if ! grep -qF 'include "/etc/bind/debian-custom-zones.conf";' \
    /etc/bind/named.conf.local; then
    echo 'include "/etc/bind/debian-custom-zones.conf";' \
        >> /etc/bind/named.conf.local
fi

# 8. Generate DNS records
SERIAL=$(date +%Y%m%d%H)

cat > "/etc/bind/db.$DOMAIN" <<EOF
\$TTL 86400

@ IN SOA ns1.$DOMAIN. admin.$DOMAIN. (
    $SERIAL
    3600
    1800
    604800
    86400
)

@       IN NS ns1.$DOMAIN.

ns1     IN A $IP
$HOST   IN A $IP
EOF

chown root:bind "/etc/bind/db.$DOMAIN"
chmod 640 "/etc/bind/db.$DOMAIN"

# 9. Validate configuration
echo
echo "[+] Memeriksa konfigurasi..."

named-checkconf
named-checkzone "$DOMAIN" "/etc/bind/db.$DOMAIN"

# 10. Start BIND9 (Fixed systemctl enable for Debian 11/12)
echo
echo "[+] Mengaktifkan BIND9..."

systemctl enable named
systemctl restart bind9

if ! systemctl is-active --quiet bind9; then
    echo "BIND9 gagal berjalan!"
    journalctl -u bind9 -n 30 --no-pager
    exit 1
fi

# 11. Test DNS
echo
echo "======================================"
echo "       BIND9 BERHASIL AKTIF"
echo "======================================"

echo "IP DNS : $IP"
echo "Domain : $DOMAIN"
echo "Host   : $HOST.$DOMAIN"

echo
echo "[+] Pengujian DNS lokal:"

dig +short @"$IP" "$HOST.$DOMAIN"

echo
echo "[+] Status service:"
systemctl is-active bind9

echo
echo "Selesai! Backup: $BACKUP"
