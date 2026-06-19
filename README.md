# 🥗 HalalEats - Premium Halal Discovery & Booking App

HalalEats adalah aplikasi mudah alih premium yang membantu pengguna mencari restoran halal yang disahkan, melihat bukti sijil halal, dan membuat tempahan meja secara efisien.

## 👥 Akaun Ujian (Demo Credentials)
Gunakan akaun di bawah untuk menguji fungsi peranan (Role) yang berbeza:

| Role | Email | Password |
| :--- | :--- | :--- |
| **Restaurant Owner** | aqil@test.com | password123 |
| **Regular Customer** | adam@test.com | password123 |

## 💡 Nota Penting untuk Penguji (Evaluation Note)
Oleh kerana had kuota pada pelan percuma **Firebase Storage**, fungsi muat naik fail melalui **"Pick from Gallery"** mungkin akan mengalami gangguan akses. 

**Saranan Pengujian:** Sila gunakan fungsi **"Paste Direct URL"** yang disediakan dalam borang (Restoran, Sijil Halal, & Menu). Anda boleh menampal mana-mana pautan imej dari internet untuk melihat paparan data yang selari (*tally*) secara real-time.

## 🚀 Cara Menjalankan Aplikasi (Setup)
1. **Clone Repository**: `git clone https://github.com/Sleven915/HalalFood_App.git`
2. **Install Library**: Jalankan perintah `flutter pub get` di terminal perisian anda.
3. **Run App**: Sambungkan peranti Android/Emulator dan jalankan perintah `flutter run`.

## ✨ Ciri-Ciri Utama (Key Features)
*   **Verification System**: Pemilik boleh memuat naik/menampal URL Sijil Halal sebagai bukti sahih.
*   **Hybrid Booking**: Sistem tempahan meja manual dengan bantuan rujukan waktu operasi yang tersusun kemas.
*   **Owner Dashboard**: Statistik real-time bagi jumlah tempahan dan ulasan pelanggan.
*   **Permissions Logic**: Sekatan ulasan bagi pemilik restoran (Integriti Data) dan pengurusan menu eksklusif.
*   **Booking History**: Simpanan rekod tempahan yang telah tamat atau dibatalkan untuk penyelidikan.

## 🛠️ Teknologi (Tech Stack)
*   **Frontend**: Flutter (Dart Framework)
*   **Backend**: Firebase (Firestore, Auth, Storage)
*   **Version Control**: GitHub
