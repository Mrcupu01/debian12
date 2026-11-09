# Debian 12 BIND9 Automatic Setup

Bash script untuk melakukan instalasi dan konfigurasi **DNS Server menggunakan BIND9** secara otomatis pada Debian 12.

Script ini dibuat untuk mempermudah administrator dalam membangun DNS Server lokal tanpa harus melakukan konfigurasi BIND9 secara manual satu per satu.

Cocok digunakan untuk praktik jaringan komputer, administrasi server, dan pembelajaran TKJ.

## ✨ Features

- Deteksi otomatis network interface.
- Deteksi otomatis IPv4 Address.
- Deteksi otomatis subnet menggunakan Python 3.
- Konfigurasi domain lokal.
- Konfigurasi hostname server.
- Instalasi BIND9 otomatis.
- Instalasi DNS Utilities.
- Backup konfigurasi BIND9 sebelumnya.
- Konfigurasi DNS Forwarders:
  - Cloudflare (`1.1.1.1`)
  - Google (`8.8.8.8`)
- Membuat Forward DNS Zone.
- Membuat DNS A Record.
- Konfigurasi ACL untuk jaringan lokal.
- Membatasi DNS Query berdasarkan jaringan yang dipercaya.
- Mengaktifkan DNS Recursion untuk jaringan lokal.
- Validasi konfigurasi menggunakan `named-checkconf`.
- Validasi DNS Zone menggunakan `named-checkzone`.
- Mengaktifkan service BIND9 secara otomatis.
- Restart BIND9 setelah konfigurasi.
- Pengujian DNS menggunakan `dig`.

## 📋 Requirements

- Debian 12 (Bookworm).
- Bash.
- Python 3.
- iproute2.
- Koneksi internet untuk instalasi paket.
- Hak akses root (`sudo`).

Paket yang akan diinstal otomatis:

- `bind9`
- `bind9-utils`
- `dnsutils`

## 📦 Installation

Clone repository:

```bash
git clone https://github.com/Mrcupu01/debian12.git
```

Masuk ke direktori:

```bash
cd debian12
```

Berikan permission:

```bash
chmod +x a.sh
```

## 🚀 Usage

Jalankan script menggunakan sudo:

```bash
sudo ./a.sh
```

Script akan mendeteksi konfigurasi jaringan secara otomatis.

### Configuration

Script akan meminta beberapa informasi:

| Parameter | Keterangan |
|---|---|
| Interface | Network interface yang digunakan |
| Server IP | IP Address server yang terdeteksi |
| Subnet | Subnet jaringan yang terdeteksi |
| Domain | Nama domain lokal |
| Hostname | Nama host DNS Server |

### Example

Contoh konfigurasi jaringan:

```text
Interface : enp0s3
Server IP : 192.168.10.10
Subnet    : 192.168.10.0/24
```

Pengisian konfigurasi:

```text
Domain lokal [tkj.test]: tkj.test
Nama host [server]: server
```

Hasil konfigurasi:

```text
DNS Server : 192.168.10.10
Domain     : tkj.test
Hostname   : server.tkj.test
DNS Record : 192.168.10.10
```

Sebelum instalasi dimulai, script akan menampilkan ringkasan konfigurasi dan meminta konfirmasi.

## ⚙️ BIND9 Configuration

Script akan membuat dan mengatur beberapa file konfigurasi BIND9.

### Main Configuration

Lokasi konfigurasi:

```text
/etc/bind/named.conf
/etc/bind/named.conf.options
/etc/bind/named.conf.local
```

### DNS Zone Configuration

Script membuat file:

```text
/etc/bind/debian-custom-zones.conf
```

File tersebut digunakan untuk mendaftarkan DNS Zone lokal.

### Forward DNS Zone

File DNS Zone dibuat secara otomatis berdasarkan nama domain.

Contoh:

```text
/etc/bind/db.tkj.test
```

DNS Record yang dibuat:

| Record | Value |
|---|---|
| SOA | ns1.tkj.test |
| NS | ns1.tkj.test |
| A | ns1.tkj.test → 192.168.10.10 |
| A | server.tkj.test → 192.168.10.10 |

### DNS Forwarders

BIND9 menggunakan DNS Forwarder untuk meneruskan permintaan domain yang tidak terdapat dalam DNS lokal.

```text
Cloudflare : 1.1.1.1
Google     : 8.8.8.8
```

## 🔍 Verify Configuration

Periksa status BIND9:

```bash
sudo systemctl status bind9
```

Periksa konfigurasi:

```bash
sudo named-checkconf
```

Periksa DNS Zone:

```bash
sudo named-checkzone tkj.test /etc/bind/db.tkj.test
```

Tes domain lokal:

```bash
dig @127.0.0.1 server.tkj.test
```

Tes DNS menggunakan IP Server:

```bash
dig @192.168.10.10 server.tkj.test
```

Tes resolusi domain internet:

```bash
dig @127.0.0.1 google.com
```

## 🔄 Service Management

Restart BIND9:

```bash
sudo systemctl restart bind9
```

Menjalankan BIND9:

```bash
sudo systemctl start bind9
```

Menghentikan BIND9:

```bash
sudo systemctl stop bind9
```

Mengaktifkan BIND9 saat boot:

```bash
sudo systemctl enable bind9
```

Melihat log BIND9:

```bash
sudo journalctl -u bind9
```

## 💾 Backup Configuration

Script secara otomatis membuat backup konfigurasi BIND9 sebelum melakukan perubahan.

Lokasi backup:

```text
/root/bind9-backup-TIMESTAMP/
```

Backup mencakup konfigurasi utama dan DNS Zone yang sudah ada apabila tersedia.

## ⚠️ Notes

- Script dirancang untuk Debian 12.
- Pastikan server memiliki IPv4 Address sebelum menjalankan script.
- Sebaiknya gunakan Static IP agar alamat DNS Server tidak berubah.
- Script tidak mengatur Static IP Address.
- Domain lokal default adalah `tkj.test`.
- DNS Query dan Recursion dibatasi untuk localhost dan subnet server yang terdeteksi.
- DNS Forwarder membutuhkan koneksi internet.
- Pastikan port DNS 53 UDP dan TCP dapat diakses oleh komputer klien.
- Script membuat Forward Zone, bukan Reverse Zone.
- Backup konfigurasi dibuat sebelum perubahan dilakukan.

## 🎯 Purpose

Proyek ini dibuat sebagai latihan administrasi sistem Linux dan konfigurasi DNS Server menggunakan BIND9 pada Debian 12.

Tujuan utamanya adalah mempermudah proses deployment DNS Server untuk kebutuhan praktik TKJ, pembelajaran jaringan komputer, dan simulasi infrastruktur jaringan lokal.

## 📄 License

This project is licensed under the **GNU General Public License v2.0 (GPL-2.0)**.

You are free to use, study, modify, and redistribute this software under the terms of GPL-2.0.

See the [LICENSE](LICENSE) file for details.

---

**Debian 12 BIND9 Automatic Setup** — Automated DNS Server installation and configuration for Debian Linux.
