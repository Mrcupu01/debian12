
#!/bin/bash

# Debian 12 - Custom Static IP
# DNS otomatis menggunakan IP sendiri

if [[ $EUID -ne 0 ]]; then
    echo "Jalankan: sudo ./set-ip.sh"
    exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
    echo "NetworkManager tidak ditemukan!"
    exit 1
fi

echo "===== DEBIAN CUSTOM IP ====="
echo

nmcli device status
echo

read -rp "Interface (contoh enp0s3): " IFACE
read -rp "IP dari guru (contoh 192.168.1.10): " IP

read -rp "Prefix subnet [24]: " PREFIX
PREFIX=${PREFIX:-24}

read -rp "Gateway (kosong jika tidak tahu): " GW

# Validasi IP
if ! python3 -c 'import ipaddress,sys; ipaddress.IPv4Address(sys.argv[1])' "$IP" 2>/dev/null; then
    echo "IP tidak valid!"
    exit 1
fi

if [[ ! "$PREFIX" =~ ^[0-9]+$ ]] || (( PREFIX < 1 || PREFIX > 32 )); then
    echo "Prefix tidak valid!"
    exit 1
fi

if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "Interface tidak ditemukan!"
    exit 1
fi

CON=$(nmcli -g GENERAL.CONNECTION device show "$IFACE")

if [[ -z "$CON" || "$CON" == "--" ]]; then
    echo "Koneksi NetworkManager tidak ditemukan!"
    exit 1
fi

echo
echo "===== KONFIGURASI ====="
echo "Interface : $IFACE"
echo "IP        : $IP/$PREFIX"
echo "Gateway   : ${GW:-Tidak diatur}"
echo "DNS       : $IP"
echo

read -rp "Terapkan? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "Dibatalkan."
    exit 0
fi

ARGS=(
    connection modify "$CON"
    ipv4.method manual
    ipv4.addresses "$IP/$PREFIX"
    ipv4.dns "$IP"
    ipv4.ignore-auto-dns yes
)

if [[ -n "$GW" ]]; then
    ARGS+=(ipv4.gateway "$GW")
else
    ARGS+=(ipv4.gateway "")
fi

nmcli "${ARGS[@]}"

echo "Mengaktifkan konfigurasi..."
nmcli connection up "$CON"

echo
echo "===== HASIL ====="
ip -br addr show "$IFACE"
ip route
