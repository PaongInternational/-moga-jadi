☁️ XipserCloud - Minecraft Server Host (Termux & Ngrok)
XipserCloud adalah solusi one-click untuk menjalankan server Minecraft PaperMC (Java Edition) dan Bedrock Edition secara stabil menggunakan Termux dan Ngrok di perangkat Android.
Skrip ini mengatasi masalah umum seperti instalasi paket yang gagal, koneksi Ngrok yang tidak stabil, dan kegagalan penyimpanan dunia (korup).
✨ Fitur Unggulan
 * Zero-Error Setup (Self-Healing): Menginstal semua dependensi (openjdk-17, ngrok, screen, dll.) secara otomatis dan robust.
 * Ngrok Guaranteed TCP Tunnel: Menggunakan file konfigurasi .yml Ngrok untuk menjamin koneksi TCP yang stabil untuk Minecraft.
 * Cross-Platform (Geyser/Floodgate): Mendukung pemain Java Edition (PC) dan Bedrock Edition (Mobile) secara bersamaan.
 * Safe Shutdown: Perintah shutdown otomatis mengirim save-all ke server, mencegah korupsi dunia (world corruption).
 * Sistem Monitoring Otomatis:
   * Memantau sesi screen server. Jika server crash, server akan dimatikan dengan aman.
   * Memantau status baterai (membutuhkan termux-api). Jika baterai sangat rendah dan tidak terhubung ke charger, server akan mati secara otomatis.
 * Manajemen RAM: Atur alokasi RAM dengan perintah sederhana.
 * Admin Otomatis: Otomatis memberikan status Operator (OP) kepada pemain yang terdaftar di admin_database.txt.
🛠️ Instalasi & Penggunaan
Langkah 1: Clone Repositori
pkg update -y && pkg install git -y
git clone [https://source.android.com/docs/setup/reference/repo](https://source.android.com/docs/setup/reference/repo)
cd XipserCloud

Langkah 2: Berikan Izin Eksekusi
Ini penting agar skrip dapat berjalan.
chmod +x xipsercloud.sh

Langkah 3: Konfigurasi File
 * Token Ngrok: Pastikan token Ngrok Anda sudah disematkan dalam file xipsercloud.sh.
 * Admin: Edit file admin_database.txt dan masukkan username Minecraft yang ingin dijadikan OP, satu per baris.
🚀 Menjalankan Server
Gunakan perintah utama ini untuk memulai server. Skrip akan mengurus instalasi, unduhan server (paper.jar), dan koneksi Ngrok.
./xipsercloud.sh start

🛑 Perintah Manajemen
| Perintah | Fungsi | Catatan |
|---|---|---|
| ./xipsercloud.sh start | Mulai Server. | Memulai server, Ngrok, dan monitor. |
| ./xipsercloud.sh shutdown | Matikan Server Aman. | Wajib digunakan. Memastikan save-all dan menutup semua sesi screen. |
| ./xipsercloud.sh set_ram 6G | Ubah Alokasi RAM. | Contoh: 6G (6 GB) atau 8192M (8192 MB). Akan diterapkan pada start berikutnya. |
| screen -r mc_server | Masuk ke Konsol. | Untuk mengirim perintah ke server (misalnya: give XipserAdmin diamond 64). |
| tail -f ngrok.log | Cek Log Ngrok. | Berguna jika Ngrok gagal menampilkan alamat (IP). |
⚙️ Detail Konfigurasi
Alokasi RAM (config_ram.txt)
Secara default skrip menggunakan 4096M (4GB). Anda dapat mengubahnya menggunakan perintah set_ram atau mengedit file config_ram.txt (jika sudah dibuat).
Multi-Platform (GeyserMC & Floodgate)
 * Server berjalan di Port 25565.
 * Pemain Java (PC) menggunakan alamat Ngrok lengkap: tcp://[alamat_ngrok]:[port_ngrok].
 * Pemain Bedrock (HP) menggunakan Host: [alamat_ngrok] dan Port: 19132.
Pastikan plugin Geyser-Spigot dan floodgate-spigot berhasil diunduh di folder plugins/.
