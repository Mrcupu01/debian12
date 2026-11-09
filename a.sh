
#!/usr/bin/env bash

# Debian Custom IP
# Automatic Network Manager Detection
# License: GNU GPL v2.0

set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: Jalankan dengan sudo."
    exit 1
fi

echo "=================================="
echo "       DEBIAN CUSTOM IP"
echo "=================================="
echo

# Detect available network managers
detect_manager() {
    if compgen -G "/etc/netplan/*.yaml" >/dev/null &&
       command -v netplan >/dev/null 2>&1; then
        echo "netplan"
    elif systemctl is-active --quiet NetworkManager &&
         command -v nmcli >/dev/null 2>&1; then
        echo "NetworkManager"
    elif systemctl is-active --quiet systemd-networkd; then
        echo "systemd-networkd"
    elif systemctl is-active --quiet networking &&
         command -v ifup >/dev/null 2>&1; then
        echo "ifupdown"
    else
        echo "unknown"
    fi
}

MANAGER=$(detect_manager)

echo "[+] Network manager terdeteksi: $MANAGER"
echo

if [[ "$MANAGER" == "unknown" ]]; then
    echo "Tidak menemukan network manager yang aktif."
    exit 1
fi

# Show network interfaces
echo "Network interfaces:"
ip -br link
echo

read -rp "Interface: " IFACE
read -rp "IP Address: " IP
read -rp "Prefix [24]: " PREFIX
PREFIX=${PREFIX:-24}
read -rp "Gateway (kosong jika tidak tahu): " GW

# Validate interface
if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "Interface tidak ditemukan!"
    exit 1
fi

# Validate IP and prefix
if ! python3 - "$IP" "$PREFIX" "$GW" <<'PY'
import ipaddress
import sys

try:
    ipaddress.IPv4Address(sys.argv[1])
    prefix = int(sys.argv[2])
    if not 1 <= prefix <= 32:
        raise ValueError("Prefix harus 1-32")
    if sys.argv[3]:
        ipaddress.IPv4Address(sys.argv[3])
except ValueError as e:
    print("Konfigurasi tidak valid:", e)
    sys.exit(1)
PY
then
    exit 1
fi

DNS="$IP"

echo
echo "========== KONFIGURASI =========="
echo "Manager   : $MANAGER"
echo "Interface : $IFACE"
echo "IP        : $IP/$PREFIX"
echo "Gateway   : ${GW:-Tidak diatur}"
echo "DNS       : $DNS"
echo "================================"
echo

read -rp "Terapkan konfigurasi? (y/n): " CONFIRM
[[ "$CONFIRM" == "y" ]] || exit 0

# NetworkManager
if [[ "$MANAGER" == "NetworkManager" ]]; then

    CON=$(nmcli -g GENERAL.CONNECTION device show "$IFACE")

    if [[ -z "$CON" || "$CON" == "--" ]]; then
        echo "Tidak ada koneksi NetworkManager."
        exit 1
    fi

    nmcli connection modify "$CON" \
        ipv4.method manual \
        ipv4.addresses "$IP/$PREFIX" \
        ipv4.gateway "$GW" \
        ipv4.dns "$DNS" \
        ipv4.ignore-auto-dns yes

    nmcli connection up "$CON"

# Netplan
elif [[ "$MANAGER" == "netplan" ]]; then

    FILE="/etc/netplan/99-debian-custom-ip.yaml"

    if [[ -e "$FILE" ]]; then
        cp -a "$FILE" "$FILE.bak"
    fi

    cat > "$FILE" <<EOF
network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: false
      addresses:
        - $IP/$PREFIX
EOF

    if [[ -n "$GW" ]]; then
        cat >> "$FILE" <<EOF
      routes:
        - to: default
          via: $GW
EOF
    fi

    cat >> "$FILE" <<EOF
      nameservers:
        addresses:
          - $DNS
EOF

    chmod 600 "$FILE"
    netplan generate
    netplan apply

# systemd-networkd
elif [[ "$MANAGER" == "systemd-networkd" ]]; then

    FILE="/etc/systemd/network/99-debian-custom-ip.network"

    if [[ -e "$FILE" ]]; then
        cp -a "$FILE" "$FILE.bak"
    fi

    cat > "$FILE" <<EOF
[Match]
Name=$IFACE

[Network]
Address=$IP/$PREFIX
DNS=$DNS
EOF

    if [[ -n "$GW" ]]; then
        cat >> "$FILE" <<EOF
Gateway=$GW
EOF
    fi

    networkctl reload
    networkctl reconfigure "$IFACE"

# ifupdown
elif [[ "$MANAGER" == "ifupdown" ]]; then

    FILE="/etc/network/interfaces.d/99-debian-custom-ip"

    if grep -RqsE "^[[:space:]]*iface[[:space:]]+$IFACE[[:space:]]+inet" \
        /etc/network/interfaces /etc/network/interfaces.d/ 2>/dev/null; then
        echo "Interface sudah memiliki konfigurasi ifupdown."
        echo "Batalkan agar tidak membuat konfigurasi duplikat."
        exit 1
    fi

    mkdir -p /etc/network/interfaces.d

    if ! grep -qE '^[[:space:]]*source(-directory)?[[:space:]]+/etc/network/interfaces.d' \
        /etc/network/interfaces; then
        echo "source /etc/network/interfaces.d/*" >> /etc/network/interfaces
    fi

    cat > "$FILE" <<EOF
auto $IFACE
iface $IFACE inet static
    address $IP
    netmask $(python3 -c "import ipaddress; print(ipaddress.IPv4Network('0.0.0.0/$PREFIX').netmask)")
EOF

    if [[ -n "$GW" ]]; then
        echo "    gateway $GW" >> "$FILE"
    fi

    if command -v resolvconf >/dev/null 2>&1; then
        echo "    dns-nameservers $DNS" >> "$FILE"
    else
        echo "Peringatan: resolvconf tidak tersedia."
        echo "DNS perlu dikonfigurasi terpisah."
    fi

    echo "Konfigurasi disimpan di $FILE"
    echo "Terapkan saat ada akses lokal: ifdown $IFACE && ifup $IFACE"
fi

echo
echo "=================================="
echo "Konfigurasi selesai!"
echo "=================================="

ip -br addr show "$IFACE"
ip route
