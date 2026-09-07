# PRODUCT REQUIREMENT DOCUMENT (PRD)

**Nama Produk:** DevFlow  
**Status Dokumen:** Final Draft (Migrated to Firebase)  
**Versi:** 1.1  
**Target Platform:** Multiplatform (Desktop, Web, Mobile) via Flutter  
**Backend & Database:** Firebase (Cloud Firestore, Firebase Authentication, Firebase Core)  
**Dokumentasi:** Product & Technical Specification  

---

## DAFTAR ISI
1. Inti Masalah & Tujuan Sistem (Problem & Goal)
2. Target Pengguna & Platform
3. Arsitektur Komponen & Struktur Menu
4. Alur Kerja Aplikasi (End-to-End User Flow)
5. Landasan Teknologi & Arsitektur Sistem
6. Skema Basis Data Firebase (Cloud Firestore) & Security Rules
7. Kebutuhan Fungsional (Functional Requirements)
8. Desain Responsif Lintas Platform (Adaptive Layout Strategy)
9. Kebutuhan Non-Fungsional (Non-Functional Requirements)
10. Rencana Pentahapan Implementasi (Milestones)

---

## 1. INTI MASALAH & TUJUAN SISTEM (PROBLEM & GOAL)

### 1.1 Masalah Utama (Problem Statement)
- **Kehilangan Model Mental (Context Loss):** Saat berpindah tugas (*context switching*) atau beristirahat dari sesi ngoding, software engineer sering lupa alur data, peran state tersembunyi, atau alasan arsitektur di balik baris kode tertentu.
- **Friksi Dokumentasi Konvensional:** Aplikasi catatan umum (seperti Notion atau Obsidian) terlalu bebas dan memakan waktu untuk mendokumentasikan logika mikro, sehingga developer enggan menggunakannya saat lelah di akhir sesi ngoding.
- **Pencemaran Kode Sumber (Code Smells):** Kebiasaan meninggalkan komentar panjang seperti `// Catatan: ...` atau `// TODO: ...` di berkas proyek membuat kode kotor, berantakan, dan berisiko ikut ter-commit ke repositori produksi.

### 1.2 Tujuan Aplikasi (Product Goal)
DevFlow dirancang sebagai *"asisten serah terima konteks untuk diri sendiri"* (*self-handover tool*). Aplikasi ini berfungsi menjembatani memori kerja developer antar-sesi ngoding dengan tiga pilar:
1. **Minim Beban Kognitif:** Proses pencatatan dibuat sangat cepat ($\le$ 2 menit) menggunakan struktur formulir kaku berurutan.
2. **Konteks Nyata Tanpa Risiko:** Membaca berkas proyek secara *read-only* dengan catatan baris (*inline annotations*) yang disimpan di Firebase Firestore, tanpa memodifikasi berkas sumber di disk lokal.
3. **Penyambung Titik Mulai (Instant Recall):** Menampilkan apa yang terakhir dikerjakan dan langkah konkret berikutnya saat aplikasi dibuka kembali.

---

## 2. TARGET PENGGUNA & PLATFORM
- **Target Pengguna:** Software engineer, mobile/web developer, dan solo programmer yang mengelola banyak berkas atau multi-proyek sekaligus.
- **Platform Target:**
  - **Desktop (macOS / Windows / Linux):** Lingkungan kerja utama saat ngoding, mendukung akses langsung ke sistem berkas lokal.
  - **Web:** Akses fleksibel melalui browser untuk monitoring alur kerja dan catatan tanpa instalasi.
  - **Mobile (Android / iOS):** Akses cepat saat bepergian untuk membaca alur logika atau mencentang tugas teknis.

---

## 3. ARSITEKTUR KOMPONEN & STRUKTUR MENU
DevFlow mengadopsi hierarki berbasis Workspace Folder. Sidebar kiri hanya menampilkan folder-folder proyek yang terhubung demi menjaga visual tetap bersih dan fokus.

Setiap folder proyek memiliki empat instrumen utama yang terisolasi:
```text
[ Connected Folder / Workspace ]
       │
       ├── 1. Files (Daftar Berkas Proyek)
       ├── 2. Code & Annotations (Viewer Read-Only + Catatan Baris)
       ├── 3. Jurnal / DevLog (Step-by-Step Logic Flow)
       └── 4. TodoList (Antrean Tugas Teknis)
```

### Tabel Rincian 4 Fitur Utama
| Fitur | Fungsi Utama | Karakteristik Penting |
| :--- | :--- | :--- |
| **Workspace Sidebar** | Mengelola daftar repositori/folder lokal yang dihubungkan. | Menampilkan daftar proyek aktif; memilih folder akan memfilter konteks seluruh data pada tab kerja. |
| **Files** | Menampilkan struktur pohon berkas (*directory tree*) dari folder yang dipilih. | Navigasi cepat untuk memilih berkas yang ingin diperiksa logikanya tanpa distraksi editor. |
| **Code & Annotations** | Membaca berkas sumber dan menempelkan penjelasan di baris kode tertentu. | 100% Read-Only. Catatan disimpan di Firestore dengan menyimpan referensi `line_number` dan cuplikan kode (`code_snippet`) sebagai pengaman pergeseran baris. |
| **Jurnal / DevLog** | Mencatat alur logika bisnis (*business logic*) per fitur yang baru selesai dikoding. | Menggunakan format berurutan kaku (Step 1 $\rightarrow$ Step 2 $\rightarrow$ Step 3), penanda berkas krusial, dan kartu serah terima *"Next Todo"*. |
| **Project Todo List** | Menampung antrean tugas teknis per proyek. | Terisolasi per folder proyek, mendukung quick add via `Enter`, penanda prioritas, dan filter status. |

---

## 4. ALUR KERJA APLIKASI (END-TO-END USER FLOW)

### Fase A: Persiapan Proyek (Setup Workspace)
1. Pengguna membuka DevFlow, lalu menekan tombol `[+ Connect Folder]`.
2. Folder proyek lokal dipilih melalui sistem pemilih direktori dan masuk ke daftar sidebar sebagai Workspace aktif.
3. Aplikasi memetakan berkas di dalam folder tersebut untuk ditampilkan pada tab Files.

### Fase B: Selesai / Jeda Ngoding (The Logging Flow)
1. Setelah menyelesaikan suatu logika di VS Code, pengguna beralih ke jendela DevFlow.
2. **Jika butuh anotasi kode:** Buka tab Code & Annotations, pilih berkas, arahkan kursor ke baris kode penting, klik ikon `[+]`, lalu ketik alasan logika baris tersebut tanpa merusak berkas asli.
3. **Mencatat alur besar:** Buka tab Jurnal, klik `[+ Catat Alur Baru]`, isi urutan langkah alur secara ringkas (poin 1, 2, dan 3), pilih berkas terkait (*Key Files*), lalu tulis satu baris catatan serah terima (*Next Todo*).
4. Klik simpan. Seluruh proses selesai dalam 1–2 menit dan tersimpan di Cloud Firestore.

### Fase C: Memulai Kembali / Pindah Fitur (The Recall Flow)
1. Saat kembali ngoding keesokan harinya, buka DevFlow dan pilih folder proyek terkait.
2. Kartu *"Last Dikerjakan"* di tab Jurnal langsung memperlihatkan alur fitur terakhir beserta langkah yang harus dilanjutkan hari ini.
3. Jika lupa implementasi fungsi tertentu, buka tab Code & Annotations untuk membaca kode beserta catatan penjelasannya.
4. Buka tab TodoList untuk mencentang tugas yang sudah selesai dan mengambil antrean tugas berikutnya.

---

## 5. LANDASAN TEKNOLOGI & ARSITEKTUR SISTEM
- **Frontend Framework:** Flutter 3+ (Single Codebase untuk Desktop, Web, dan Mobile).
- **State Management:** Riverpod (`flutter_riverpod`) untuk manajemen state modular lintas komponen.
- **Backend & Basis Data: Firebase**
  - **Cloud Firestore:** Database NoSQL dokumen & koleksi untuk entitas pengguna, workspaces, jurnal alur logika, anotasi kode, dan todo list.
  - **Firebase Authentication:** Autentikasi pengguna berbasis email/password atau OAuth untuk sinkronisasi multiplatform.
  - **Firebase Realtime Listener:** Sinkronisasi instan antar-perangkat menggunakan Firestore stream snapshots (`.snapshots()`).
- **Komponen Syntax Highlighter:** Package Flutter `flutter_highlight` untuk pewarnaan sintaksis pada mode *read-only*.
- **Akses Sistem Berkas:**
  - **Desktop (macOS/Windows/Linux):** `dart:io` dan `file_picker` untuk membaca struktur folder dan berkas lokal secara langsung (*zero-write*).
  - **Web:** File System Access API / cache sesi demo.
  - **Mobile:** Menampilkan replika berkas tersimpan atau referensi cloud di fase lanjutan.

---

## 6. SKEMA BASIS DATA FIREBASE (CLOUD FIRESTORE) & SECURITY RULES

Struktur data NoSQL DevFlow menggunakan model dokumen dengan hierarki root collection dan sub-koleksi di bawah tiap workspace untuk isolasi data yang bersih.

### 6.1 Struktur Koleksi & Dokumen Firestore

#### 1. Koleksi `users`
- **Path:** `/users/{uid}`
- **Fields:**
  ```json
  {
    "uid": "STRING (Firebase Auth UID)",
    "email": "STRING",
    "created_at": "TIMESTAMP"
  }
  ```

#### 2. Koleksi `workspaces`
- **Path:** `/workspaces/{workspace_id}`
- **Fields:**
  ```json
  {
    "workspace_id": "STRING (UUID / Auto-generated ID)",
    "user_id": "STRING (Owner User UID)",
    "name": "STRING (Nama Workspace / Folder)",
    "local_path": "STRING (Path absolut di sistem file lokal)",
    "created_at": "TIMESTAMP"
  }
  ```

#### 3. Sub-koleksi `flow_entries` (di bawah tiap workspace)
- **Path:** `/workspaces/{workspace_id}/flow_entries/{entry_id}`
- **Fields:**
  ```json
  {
    "id": "STRING (Document ID)",
    "workspace_id": "STRING",
    "feature_name": "STRING (Nama fitur)",
    "flow_steps": ["1. Validasi input", "2. Panggil API auth", "3. Simpan token"],
    "key_files": ["lib/auth/auth_service.dart", "lib/auth/auth_controller.dart"],
    "state_notes": "STRING (Catatan payload / state)",
    "next_todo": "STRING (Handover konkret yang harus dilanjutkan)",
    "tags": ["auth", "security"],
    "created_at": "TIMESTAMP"
  }
  ```

#### 4. Sub-koleksi `code_annotations` (di bawah tiap workspace)
- **Path:** `/workspaces/{workspace_id}/code_annotations/{annotation_id}`
- **Fields:**
  ```json
  {
    "id": "STRING (Document ID)",
    "workspace_id": "STRING",
    "file_relative_path": "STRING (Contoh: lib/controllers/auth_controller.dart)",
    "line_number": "NUMBER (Nomor baris integer)",
    "code_snippet": "STRING (Cuplikan baris kode sebagai penanda)",
    "note": "STRING (Catatan logika)",
    "created_at": "TIMESTAMP"
  }
  ```

#### 5. Sub-koleksi `project_todos` (di bawah tiap workspace)
- **Path:** `/workspaces/{workspace_id}/project_todos/{todo_id}`
- **Fields:**
  ```json
  {
    "id": "STRING (Document ID)",
    "workspace_id": "STRING",
    "title": "STRING (Judul tugas)",
    "priority": "STRING ('low' | 'medium' | 'high')",
    "is_completed": "BOOLEAN (Default: false)",
    "created_at": "TIMESTAMP"
  }
  ```

### 6.2 Aturan Keamanan (Firestore Security Rules)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function: Memeriksa apakah user telah terautentikasi
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function: Memeriksa apakah user adalah pemilik data
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Aturan untuk koleksi users
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }

    // Aturan untuk koleksi workspaces
    match /workspaces/{workspaceId} {
      allow create: if isAuthenticated() && request.resource.data.user_id == request.auth.uid;
      allow read, update, delete: if isAuthenticated() && resource.data.user_id == request.auth.uid;

      // Helper function untuk memeriksa kepemilikan workspace parent
      function isWorkspaceOwner() {
        return isAuthenticated() && 
          get(/databases/$(database)/documents/workspaces/$(workspaceId)).data.user_id == request.auth.uid;
      }

      // Sub-koleksi flow_entries
      match /flow_entries/{entryId} {
        allow read, write: if isWorkspaceOwner();
      }

      // Sub-koleksi code_annotations
      match /code_annotations/{annotationId} {
        allow read, write: if isWorkspaceOwner();
      }

      // Sub-koleksi project_todos
      match /project_todos/{todoId} {
        allow read, write: if isWorkspaceOwner();
      }
    }
  }
}
```

---

## 7. KEBUTUHAN FUNGSIONAL (FUNCTIONAL REQUIREMENTS)

### 7.1 Manajemen Folder & Workspace
- **FR-01:** Pengguna dapat menautkan folder proyek lokal sebagai workspace baru melalui dialog pemilih direktori.
- **FR-02:** Sidebar hanya menampilkan daftar workspace; memilih satu workspace otomatis memperbarui konteks data pada tab Files, Code, Jurnal, dan TodoList.
- **FR-03:** Pengguna dapat mengganti nama alias folder atau memutuskan tautan folder dari workspace tanpa menghapus berkas fisik di disk.

### 7.2 File Explorer & Read-Only Code Viewer
- **FR-04:** Tab Files menampilkan struktur direktori dari workspace yang aktif secara hierarkis (pohon folder dan berkas).
- **FR-05:** Mengklik sebuah berkas otomatis membuka tab Code & Annotations dengan menampilkan isi berkas tersebut.
- **FR-06:** Tampilan kode bersifat strict *read-only* (tidak menyediakan kursor pengetikan atau kemampuan mutasi teks).
- **FR-07:** Penomoran baris (*line numbers*) wajib muncul di sisi kiri baris kode dengan syntax highlighting adaptif terhadap bahasa pemrograman berkas.

### 7.3 Anotasi Baris Kode (Inline Code Annotations)
- **FR-08:** Arahkan kursor (*hover*) pada nomor baris atau baris kode memunculkan tombol kecil `[+]`.
- **FR-09:** Menekan `[+]` membuka formulir anotasi inline tepat di bawah baris terkait.
- **FR-10:** Saat disimpan, sistem mencatat `file_relative_path`, `line_number`, isi teks baris kode sebagai `code_snippet`, dan teks anotasi ke Cloud Firestore.
- **FR-11:** Baris yang memiliki catatan menampilkan garis aksen penanda serta kartu anotasi yang dapat diperluas (*expandable*) langsung di bawah baris kode.
- **FR-12:** Berkas kode sumber asli di komputer pengguna sama sekali tidak ditulisi atau dimodifikasi (*Zero-Write Guarantee*).

### 7.4 Jurnal Alur Logika (Step-by-Step DevLog)
- **FR-13:** Formulir entri jurnal mewajibkan pengisian nama fitur dan langkah alur logika berupa daftar berurutan (*ordered steps*).
- **FR-14:** Setiap langkah alur dibuat dinamis: menekan Enter atau tombol `[+ Tambah Langkah]` membuat kolom input baru di bawahnya.
- **FR-15:** Pengguna dapat menyematkan daftar berkas krusial (*Key Files*) dan wajib mengisi pesan serah terima (*Next Todo*).
- **FR-16:** Beranda tab Jurnal menampilkan kartu *"Last Dikerjakan"* di posisi teratas sebagai ringkasan konteks terakhir.
- **FR-17:** Menyediakan filter pencarian instan (*instant search*) berdasarkan nama fitur, teks langkah alur, atau nama berkas.

### 7.5 Project Todo List
- **FR-18:** Setiap workspace memiliki daftar todo list terpisah di Firestore.
- **FR-19:** Tersedia kolom Quick Add di bagian atas: mengetik judul tugas dan menekan Enter langsung menyimpan tugas dengan prioritas default (*medium*).
- **FR-20:** Setiap item tugas memiliki checkbox penyelesaian, label prioritas (High, Medium, Low), dan tombol hapus.
- **FR-21:** Menyediakan filter tampilan: All, Active/Pending, dan Completed.

---

## 8. DESAIN RESPONSIF LINTAS PLATFORM (ADAPTIVE LAYOUT STRATEGY)
Penerapan tata letak di Flutter menggunakan `LayoutBuilder` untuk menyesuaikan tiga skenario perangkat:

### 8.1 Wireframe Diagram
```text
A. Desktop & Web Expanded (>= 1024px)
+----------------+-----------------------------------------------------------+
| WORKSPACES     | [Files]  [Code & Annotations]  [Jurnal]  [TodoList]       |
+----------------+-----------------------------------------------------------+
| > Demo Project | (Tampilan tab aktif mengambil area luas dengan split      |
| > Toko Bakery  |  view jika diperlukan, misal: Tree berkas di kiri dan     |
|                |  Code viewer di kanan secara berdampingan)                |
+----------------+-----------------------------------------------------------+

B. Tablet / Web Window Kecil (600px - 1023px)
+---------------------------------------------------------------------------+
| [=] Demo Project    [Files]  [Code]  [Jurnal]  [Todos]                    |
+---------------------------------------------------------------------------+
| (Sidebar workspace berupa drawer slide-out. Area tengah mengambil porsi    |
|  layar penuh untuk membaca alur dan kode)                                 |
+---------------------------------------------------------------------------+

C. Mobile Viewport (< 600px)
+-----------------------------------+
| DevFlow - Demo Project        [v] | <- Dropdown ganti workspace
+-----------------------------------+
|                                   |
| (Tampilan tumpukan vertikal /     |
|  Single-column stack)             |
| - Kartu Last Dikerjakan           |
| - List alur jurnal / todo         |
|                                   |
+-----------------------------------+
| [Files]  [Code]  [Jurnal]  [Todo] | <- Bottom Navigation Bar
+-----------------------------------+
```

### 8.2 Matriks Breakpoint
| Breakpoint | Target Perangkat | Perilaku Antarmuka |
| :--- | :--- | :--- |
| **Expanded ($\ge$ 1024px)** | Desktop (macOS/Win/Linux) & Web Browser Lebar | **Dual-Pane Split View:** Sidebar workspace menetap di sisi kiri (lebar 240px); panel kerja utama menampilkan tab aktif dengan ruang baca horizontal luas. |
| **Medium (600px – 1023px)** | Tablet Portrait & Web Window Sedang | **Collapsible Drawer View:** Sidebar workspace disembunyikan dalam tombol hamburger menu; tab navigasi utama tetap terlihat di bar atas. |
| **Compact (< 600px)** | Smartphone (Android / iOS) | **Single-Column Stack View:** Pilihan workspace berpindah ke dropdown header atas; perpindahan antar 4 fitur utama menggunakan Bottom Navigation Bar. |

---

## 9. KEBUTUHAN NON-FUNGSIONAL (NON-FUNCTIONAL REQUIREMENTS)
- **Performa (Rendering Performance):** Viewer kode menggunakan teknik *list virtualization* (`ListView.builder`) agar lancar menampilkan berkas hingga 2.000 baris tanpa penurunan frame rate (< 60 FPS).
- **Integritas Berkas (Zero-Write Guarantee):** Aplikasi tidak pernah meminta atau mengeksekusi operasi tulis (*write/modify/delete*) pada berkas kode sumber asli di komputer pengguna.
- **Keamanan Data (Security):** Seluruh data di Cloud Firestore diproteksi menggunakan aturan Firestore Security Rules berbasis UID akun pengguna (`request.auth.uid == resource.data.user_id`).
- **Ketersediaan Offline (Offline Tolerance):** Cloud Firestore menyediakan *offline persistence* secara bawaan pada platform yang didukung, menjaga data tetap dapat diakses saat offline.

---

## 10. RENCANA PENTAHAPAN IMPLEMENTASI (MILESTONES)
- **Fase 1: Setup Fondasi & Firebase Configuration**
  - Inisialisasi proyek Flutter multiplatform (Desktop, Web, Mobile).
  - Konfigurasi tema dark developer-centric dan struktur arsitektur Riverpod.
  - Setup Firebase Core, Firebase Auth, dan Cloud Firestore beserta Security Rules.
- **Fase 2: Core DevLog & Todo List (Firestore Repositories)**
  - Pembuatan modul Workspace dan antarmuka manajemen proyek.
  - Implementasi formulir alur logika berurutan (*step-by-step logger*) dan kartu Last Dikerjakan.
  - Implementasi modul Project Todo List interaktif dengan filter status dan Firestore real-time streams.
- **Fase 3: File Tree & Read-Only Code Viewer**
  - Integrasi pembaca direktori lokal (`file_picker` & `dart:io`).
  - Implementasi komponen *read-only code viewer* lengkap dengan nomor baris dan syntax highlighting.
- **Fase 4: Anotasi Baris Kode**
  - Pembangunan interaksi hover `[+]` pada baris kode dan formulir pembuatan catatan.
  - Relasi data anotasi ke Firestore menggunakan koordinat berkas, nomor baris, dan cuplikan kode.
- **Fase 5: Adaptasi Responsif & Uji Coba Multiplatform**
  - Penyesuaian antarmuka mobile (*bottom navigation*) dan desktop (*split view*).
  - Pengujian build multiplatform pada lingkungan Desktop (Windows/macOS) dan Web.