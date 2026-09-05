# 🚀 DevFlow

> **Asisten Serah Terima Konteks Diri Sendiri (*Self-Handover Tool*) untuk Developer**  
> Menjembatani memori kerja antar-sesi ngoding dengan dokumentasi terarah, anotasi baris kode *zero-write*, dan *instant recall*.

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase%20Firestore%20%26%20Auth-orange.svg?logo=firebase)](https://firebase.google.com)
[![Zero-Write Guarantee](https://img.shields.io/badge/Codebase-100%25%20Read--Only%20(Zero--Write)-success.svg)](#-prinsip-zero-write-guarantee)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Web%20%7C%20Mobile-blueviolet.svg)](#)

---

## 📌 Daftar Isi
- [Tentang DevFlow](#-tentang-devflow)
- [Masalah yang Teratasi](#-masalah-yang-teratasi)
- [Prinsip Zero-Write Guarantee](#-prinsip-zero-write-guarantee)
- [Fitur-Fitur Utama](#-fitur-fitur-utama)
- [Alur Kerja Aplikasi (User Flow)](#-alur-kerja-aplikasi-user-flow)
- [Arsitektur & Tumpukan Teknologi](#-arsitektur--tumpukan-teknologi)
- [Struktur Database Firestore](#-struktur-database-firestore)
- [Panduan Memulai (Getting Started)](#-panduan-memulai-getting-started)

---

## 💡 Tentang DevFlow

Saat berpindah tugas (*context switching*) atau beristirahat setelah sesi ngoding yang panjang, seorang developer sering kali lupa:
- *"Sampai mana alur data yang tadi saya kerjakan?"*
- *"Mengapa baris kode ini dibuat seperti ini?"*
- *"Besok saya harus mulai dari fungsi yang mana?"*

**DevFlow** hadir sebagai *"asisten serah terima konteks untuk diri sendiri"*. Aplikasi ini dirancang agar developer dapat mendokumentasikan logika mikro dan tugas teknis hanya dalam waktu **$\le$ 2 menit** di akhir sesi ngoding, sehingga saat kembali keesokan harinya, developer langsung mendapatkan gambaran utuh (*Instant Recall*) tanpa membuang waktu memahami ulang kode.

---

## 🛑 Masalah yang Teratasi

| Masalah Konvensional | Solusi DevFlow |
| :--- | :--- |
| **Kehilangan Model Mental (*Context Loss*):** Butuh waktu 15–30 menit untuk mengingat kembali variabel tersembunyi atau alur state setelah istirahat. | **Kartu "Last Dikerjakan":** Langsung terpampang di atas saat aplikasi dibuka, menampilkan alur fitur terakhir beserta langkah konkret berikutnya (*Next Todo*). |
| **Friksi Dokumentasi Umum:** Aplikasi catatan seperti Notion atau Obsidian terlalu bebas, tanpa template kaku, dan lambat dibuka saat lelah ngoding. | **Formulir Kaku Berurutan (DevLog):** Format terstruktur (Step 1 $\rightarrow$ Step 2 $\rightarrow$ Step 3) yang sangat cepat diisi via tombol Enter dinamis. |
| **Pencemaran Kode Sumber (*Code Smells*):** Kebiasaan meninggalkan komentar `// Catatan: ...` atau `// TODO: ...` di berkas proyek yang berisiko ikut ter-commit ke repositori produksi. | **Inline Annotations Eksternal:** Catatan baris kode ditempelkan langsung di visual Code Viewer dan disimpan di Firebase, tanpa menyentuh satu karakter pun pada berkas fisik. |

---

## 🛡️ Prinsip Zero-Write Guarantee

> **Aplikasi DevFlow 100% READ-ONLY terhadap berkas kode sumber fisik Anda.**

DevFlow **tidak pernah** menulis, memodifikasi, menimpa, atau menghapus berkas di dalam folder proyek Anda.
- Seluruh anotasi kode (*inline notes*), jurnal alur (*DevLog*), dan antrean tugas (*TodoList*) disimpan terpisah di **Cloud Firestore**.
- Koordinat catatan diikat dengan `file_relative_path`, `line_number`, dan cuplikan teks (`code_snippet`) sebagai pengaman pergeseran baris.

---

## ⚡ Fitur-Fitur Utama

### 1. 🗂️ Workspace Management & Multi-User Isolation
- Menghubungkan direktori proyek lokal sebagai Workspace aktif dengan satu klik.
- Sistem akun **Firebase Authentication** (Email & Password): Data setiap pengguna (workspace, catatan, devlog, todo) terisolasi secara privat berdasarkan UID pengguna.
- Mendukung opsi *Rename Alias* dan *Disconnect Workspace* tanpa menghapus folder asli di komputer.

### 2. 🌲 File Explorer & Realtime File System Watcher
- Menampilkan pohon direktori (*directory tree*) hierarkis yang bersih (otomatis menyembunyikan `.git`, `build`, `.dart_tool`, `node_modules`, dll.).
- **Live File Watcher:** Jika Anda membuat, mengubah, atau menghapus berkas di VS Code / File Explorer, pohon berkas di DevFlow otomatis ter-update secara *real-time* tanpa menutup folder yang sedang terbuka (*preserved expansion*).

### 3. 🔍 Read-Only Code Viewer & Live Code Reload
- Penampil kode sumber dengan nomor baris (*line numbers*) dan pewarnaan sintaks (*syntax highlighting*) adaptif.
- **Live Code Reload:** Memantau berkas fisik yang sedang dibuka (`File.watch`). Saat Anda menekan `Ctrl + S` di VS Code, isi kode di DevFlow langsung ter-update seketika.
- **Tombol Refresh Manual:** Ikon segarkan di header bar untuk memuat ulang kode dan anotasi kapan saja sesuai keinginan.

### 4. 💬 Inline Code Annotations
- Arahkan kursor (*hover*) pada nomor baris untuk memunculkan tombol `[+]`.
- Formulir catatan *inline* yang ringkas tepat di bawah baris terkait.
- Garis aksen penanda baris dan kartu penjelasan yang tersimpan rapi di Cloud Firestore.

### 5. 📖 Jurnal Alur Logika (DevLog)
- Form pencatatan alur logika step-by-step:
  - **Nama Fitur:** Judul besar yang bersih.
  - **Langkah Alur:** Penambahan langkah otomatis saat menekan `Enter`.
  - **Next Todo:** Instruksi serah terima konkret untuk dikerjakan selanjutnya.
  - **Opsi Tambahan (Collapsible):** Menyimpan *Key Files*, catatan state/payload, dan tags.
- **Kartu "Last Dikerjakan":** Ringkasan alur terakhir yang otomatis disematkan di posisi teratas.
- **Instant Search:** Pencarian cepat berdasarkan nama fitur, teks langkah, atau berkas kunci.

### 6. ✅ Project Todo List
- Antrean tugas teknis terisolasi per folder proyek.
- **Quick Add Bar:** Mengetik tugas dan menekan `Enter` langsung menyimpannya ke daftar.
- Filter status: *All*, *Active/Pending*, dan *Completed*.
- Penanda prioritas (*High, Medium, Low*) dan checkbox penyelesaian instan yang tersinkronisasi *real-time*.

---

## 🔄 Alur Kerja Aplikasi (User Flow)

```mermaid
flowchart TD
    A[Buka DevFlow & Login] --> B[Connect Folder Proyek Lokal]
    B --> C[Workspace Aktif Dipilih]
    
    subgraph Sesi Ngoding Berjalan
        C --> D[Buka VS Code / Editor Utama]
        D --> E[Ngoding & Implementasi Fitur]
    end

    subgraph Selesai / Jeda Ngoding (The Logging Flow - ≤ 2 Menit)
        E --> F{Butuh Dokumentasi?}
        F -->|Anotasi Baris Kode| G[Buka Tab Code Viewer -> Klik [+] -> Tulis Alasan Logika]
        F -->|Alur Bisnis Besar| H[Buka Tab Jurnal -> [+ Catat Alur Baru] -> Tulis Step 1, 2, 3 -> Tulis Next Todo]
        F -->|Tugas Baru| I[Buka Tab TodoList -> Quick Add via Enter]
        G --> J[Tersimpan Otomatis ke Cloud Firestore]
        H --> J
        I --> J
    end

    subgraph Memulai Kembali (The Recall Flow - Instant)
        J --> K[Keesokan Harinya: Buka DevFlow]
        K --> L[Lihat Kartu 'Last Dikerjakan' & Centang Todo]
        L --> M[Lanjut Ngoding dengan Konteks Penuh!]
    end
```

---

## 🛠️ Arsitektur & Tumpukan Teknologi

- **Framework:** [Flutter 3.x](https://flutter.dev) (Single Codebase untuk Desktop, Web, dan Mobile).
- **Arsitektur:** Clean Architecture + Feature-First Folder Structure.
- **State Management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod`) dengan paradigma Provider & StreamProvider.
- **Backend & Database:**
  - **Firebase Authentication:** Manajemen sesi & login pengguna.
  - **Cloud Firestore:** Database NoSQL dokumen & sub-koleksi *real-time*.
- **Syntax Highlighter:** `flutter_highlight` untuk mode *read-only*.
- **Typography:** `google_fonts` (Font Quicksand untuk UI umum dan JetBrains Mono untuk pembaca kode).
- **Filesystem Engine:** `dart:io` (`Directory.watch`, `File.watch`) & `file_picker` dengan proteksi *Windows File Locking Safe Retry*.

---

## 📂 Struktur Database Firestore

Data diorganisasikan secara modular di bawah setiap pengguna dan workspace:

```text
users/
  └── {uid}                     -> Dokumen profil user (email, created_at)

workspaces/
  └── {workspace_id}            -> Dokumen workspace (user_id, name, local_path)
        │
        ├── flow_entries/       -> Sub-koleksi catatan jurnal alur logika
        │     └── {entry_id}    -> feature_name, flow_steps, key_files, next_todo
        │
        ├── code_annotations/   -> Sub-koleksi catatan baris kode
        │     └── {annot_id}    -> file_relative_path, line_number, code_snippet, note
        │
        └── project_todos/      -> Sub-koleksi daftar tugas proyek
              └── {todo_id}     -> title, priority, is_completed, created_at
```

---

## 🚀 Panduan Memulai (Getting Started)

### 1. Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.22 atau lebih baru).
- [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) dengan komponen *"Desktop development with C++"* (untuk build Windows).
- Akun Firebase dan proyek aktif.

### 2. Instalasi Dependensi
Masuk ke direktori proyek dan unduh paket-paket yang diperlukan:
```bash
cd devflow
flutter pub get
```

### 3. Konfigurasi Firebase
Pastikan berkas `devflow/lib/firebase_options.dart` sudah terkonfigurasi dengan konfigurasi proyek Firebase Anda:
```bash
flutterfire configure
```

### 4. Menjalankan Aplikasi
Jalankan aplikasi pada platform desktop target (contoh: Windows):
```bash
flutter run -d windows
```

---

## 📝 Lisensi & Kontribusi
Aplikasi ini dikembangkan untuk kebutuhan produktivitas developer mandiri maupun tim. Kontribusi, saran fitur, dan pelaporan kendala (*issues*) sangat dipersilakan!
