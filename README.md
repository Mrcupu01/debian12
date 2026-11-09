# Debian Custom IP

Script Bash sederhana untuk mengatur konfigurasi **Static IP Address** pada Debian 12 menggunakan NetworkManager (`nmcli`).

Proyek ini dibuat untuk mempermudah konfigurasi IP Address pada komputer Linux, khususnya saat praktik jaringan dan administrasi server.

## ✨ Features

- Mengatur Static IP Address.
- Memilih network interface.
- Prefix subnet default `/24`.
- Gateway bersifat opsional.
- DNS otomatis menggunakan IP Address yang diberikan.
- Validasi IP Address dan prefix.
- Konfirmasi sebelum menerapkan konfigurasi.
- Menggunakan NetworkManager (`nmcli`).

## 📋 Requirements

- Debian 12 atau distribusi Linux berbasis Debian.
- Bash.
- NetworkManager.
- `nmcli`.
- Python 3.
- Hak akses root (`sudo`).

## 📦 Installation

Clone repository:

```bash
git clone https://github.com/USERNAME/debian-custom-ip.git
```

Masuk ke direktori:

```bash
cd debian-custom-ip
```

Berikan permission:

```bash
chmod +x set-ip.sh
```

## 🚀 Usage

Jalankan script:

```bash
sudo ./set-ip.sh
```

Script akan meminta beberapa informasi:

| Parameter | Keterangan |
|---|---|
| Interface | Network interface, contoh `enp0s3` |
| IP Address | IP yang ingin digunakan |
| Prefix | Subnet prefix, default `/24` |
| Gateway | Gateway, boleh dikosongkan |
| DNS | Otomatis menggunakan IP Address sendiri |

### Example

Misalnya kamu mendapatkan konfigurasi IP:

```text
IP Address: 192.168.10.20
Prefix: 24
Gateway: (kosong)
DNS: otomatis
```

Pengisian:

```text
Interface: enp0s3
IP dari guru: 192.168.10.20
Prefix subnet [24]: 24
Gateway (kosongkan jika tidak tahu):
```

Hasil konfigurasi:

```text
IP Address : 192.168.10.20/24
Gateway    : Tidak diatur
DNS        : 192.168.10.20
```

## 🔍 Verify Configuration

Periksa IP Address:

```bash
ip addr
```

Periksa routing:

```bash
ip route
```

Periksa DNS:

```bash
cat /etc/resolv.conf
```

## ⚠️ Notes

- Script ini dirancang untuk NetworkManager.
- Gateway dapat dikosongkan jika memang tidak tersedia.
- Prefix `/24` hanya nilai default, bukan aturan untuk semua jaringan.
- DNS otomatis diarahkan ke IP Address lokal yang dimasukkan.
- Pastikan layanan DNS seperti BIND9 sudah berjalan jika ingin menggunakan mesin ini sebagai DNS Server.
- Mengubah konfigurasi jaringan melalui SSH dapat memutus koneksi sementara.
- Pastikan IP yang digunakan tidak bertabrakan dengan perangkat lain.

## 🎯 Purpose

Proyek ini dibuat sebagai latihan administrasi sistem Linux dan konfigurasi jaringan untuk lingkungan praktik TKJ.

## 📄 License

This project is licensed under the **GNU General Public License v2.0 (GPL-2.0)**.

You are free to use, study, modify, and redistribute this software under the terms of GPL-2.0.

See the [LICENSE](LICENSE) file for details.

---

**Debian Custom IP** — Simple static IP configuration for Debian Linux.
