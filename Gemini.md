# SYSTEM SPECIFICATION: FLUTTER VIRTUALIZED DATAGRID ENGINE
**Target Platform:** Google Antigravity (Gemini 3 Agent Environment)  
**Project Type:** Flutter / Dart High-Performance Data Grid Package  
**Execution Paradigm:** Spec-Driven Development (SDD)

---

## 1. MISSION & CONTEXT BOUNDARIES

### 1.1 Goal
Mengembangkan package Flutter mandiri berupa data grid berperforma tinggi yang mampu menangani dataset besar dan data streaming *high-frequency ticks* secara realtime tanpa frame drop, dengan 2D virtualization, manipulasi kolom adaptif, dan sistem seleksi/navigasi keyboard.

### 1.2 Non-Goals (Explicitly Out of Scope)
- **NO Row Pinning:** Baris pinned/freeze row tidak diimplementasikan.
- **NO Column Width Persistence:** Nilai lebar kolom (width) tidak boleh disimpan dalam persistence storage; lebar kolom harus selalu dihitung ulang secara dinamis saat inisialisasi/layout.
- **NO Full-Grid Rebuilds:** Jangan gunakan `notifyListeners()` atau `setState()` pada level root widget untuk update data cell per detik.

---

## 2. ARCHITECTURAL REQUIREMENTS (EARS FORMAT)

### 2.1 2D Viewport Virtualization
- **REQ-PERF-01:** Sistem **harus** mengimplementasikan virtualisasi dua arah (horizontal dan vertikal) menggunakan turunan `RenderTwoDimensionalViewport` atau layout 2D kustom.
- **REQ-PERF-02:** Widget cell yang berada di luar batas viewport visible **tidak boleh** dirender di dalam element tree (wajib cell recycling).

### 2.2 Granular Reactive Updating
- **REQ-PERF-03:** Setiap baris/cell **harus** meng-subscribe identifier terisolasi (misal: `RowController` atau `CellKey(rowId, colId)`).
- **REQ-PERF-04:** Saat data streaming tiba, sistem **harus** mengisolasi mutasi dan *rebuild* hanya pada target cell/row yang terpengaruh.

### 2.3 Frame-Synced Batch Throttling
- **REQ-PERF-05:** Sistem **harus** menyediakan buffer penampung mutasi streaming dengan volume tinggi (50–100+ events/sec).
- **REQ-PERF-06:** Mutasi dari buffer **harus** di-flush ke UI state mengikuti siklus render frame menggunakan `SchedulerBinding.instance.scheduleFrameCallback`.

---

## 3. CORE FUNCTIONAL SPECIFICATIONS

### 3.1 Dual-Index Selection & Navigation
- **REQ-SEL-01:** Sistem hanya mendukung **Single Row Selection**.
- **REQ-SEL-02:** Setiap interaksi seleksi (`onRowSelected`) **wajib** mengembalikan objek index mapping:
  ```dart
  class RowIndexInfo {
    final int originalIndex; // Index murni pada dataset input awal
    final int displayIndex;  // Index visual aktif (pasca sort & filter)
    const RowIndexInfo({required this.originalIndex, required this.displayIndex});
  }
  ```
- **REQ-NAV-01:** Sistem **harus** mendukung navigasi keyboard:
  - `ArrowUp` / `ArrowDown`: Geser seleksi ke atas / bawah 1 baris.
  - `Home`: Lompat ke baris paling pertama.
  - `End`: Lompat ke baris paling akhir.
  - `PageUp` / `PageDown`: Lompat baris sebanyak visible rows viewport saat itu.

### 3.2 Column Manipulation & Layout
- **REQ-COL-01 (Freezing):** Kolom dapat dibekukan (freeze) di sisi kiri atau kanan tabel. Konten freeze column tetap statis saat horizontal scroll digerakkan.
- **REQ-COL-02 (Reordering):** Posisi kolom dapat dipindahkan melalui drag-and-drop header.
- **REQ-COL-03 (Resizing):** Pengguna dapat me-resize lebar kolom via drag handle di tepi kanan header. Double-click handle **harus** memicu fungsi *auto-fit* terhadap konten terpanjang.
- **REQ-COL-04 (Visibility):** Mendukung toggle `isVisible` per kolom tanpa menghapus instance/konfigurasi kolom.
- **REQ-COL-05 (Auto-Stretch):** Mendukung konfigurasi `minWidth` per kolom. Jika $\sum(\text{minWidth}) < \text{ViewportWidth}$, kolom otomatis merenggang secara proporsional untuk mengisi sisa ruang layar.

### 3.3 Sorting Engine
- **REQ-SORT-01:** Kolom mendukung sort:
  - Numeric (`Comparable<num>`)
  - Alphabetical (`Comparable<String>`)
  - Custom Comparator (`int Function(T a, T b)`)
- **REQ-SORT-02:** Mode sort: `Ascending`, `Descending`, `None`.

### 3.4 State Persistence (Selective)
- **REQ-STATE-01:** State tabel dapat diexport ke dan direstore dari JSON string / Map.
- **REQ-STATE-02:** Serialisasi hanya boleh mencakup:
  1. `columnOrder`: List ID kolom terurut.
  2. `sortCriteria`: Kolom ID dan `SortDirection`.
  3. `columnVisibility`: Map status boolean visibility per kolom ID.
- **REQ-STATE-03 (Strict):** Nilai lebar kolom (`width`) **dilarang** dimasukkan ke dalam payload state persistence.

### 3.5 Data Ingestion Modes & Export Helper
- **REQ-DATA-01:** Controller harus mendukung dua mode data fetch:
  - `DataFetchMode.pagination`: Halaman diskrit dengan metadata (page, limit, total).
  - `DataFetchMode.infiniteScroll`: Lazy load otomatis via callback saat scroll mencapai threshold bawah (default 80%).
- **REQ-DATA-02:** Menyediakan export utility bawaan untuk mengonversi data display aktif ke `String`:
  - `DataGridExporter.toCsv(...)`
  - `DataGridExporter.toJson(...)`

---

## 4. API & BUILDER CONTRACTS

Antigravity Agent **harus** menggunakan signature builder berikut:

```dart
// Custom Header Builder
typedef GridHeaderBuilder = Widget Function(
  BuildContext context,
  GridColumn column,
  SortDirection sortDirection,
  VoidCallback onSortToggle,
);

// Custom Cell Builder
typedef GridCellBuilder<T> = Widget Function(
  BuildContext context,
  T rowData,
  RowIndexInfo indexInfo,
  String columnId,
);

// Custom Footer Builder
typedef GridFooterBuilder = Widget Function(
  BuildContext context,
  GridColumn column,
  List<dynamic> currentVisibleData,
);
```

---

## 5. ACCEPTANCE CRITERIA (VERIFICATION TEST-SUITE)

| ID | Kategori | Kriteria Pengujian (Verification Check) |
|---|---|---|
| **AC-01** | Rendering | Scroll 100,000 baris x 50 kolom mempertahankan frame rate $\ge 55$ FPS; elemen DOM widget tidak melebihi bounding box viewport + 1 buffer row. |
| **AC-02** | Realtime | 60 updates/detik pada cell acak hanya memanggil build method pada cell bersangkutan; Root widget tidak rebuild. |
| **AC-03** | Indexing | Saat tabel disort descending, memilih baris visual index `0` mengembalikan `displayIndex: 0` dan `originalIndex` sesuai letak awal data. |
| **AC-04** | Keyboard | Menekan `PageDown` menggeser index selected row sejumlah count visible rows di layar. |
| **AC-05** | Persistence | Ekspor JSON state tidak memiliki key `columnWidth` atau `width`. Saat JSON di-load, hanya urutan kolom, sort, dan visibility yang berubah. |
| **AC-06** | Layout | Jika total lebar kolom lebih kecil dari layar, tidak ada area kosong (blank canvas) di sebelah kanan; kolom terdistribusi penuh. |

---

## 6. INSTRUCTION FOR ANTIGRAVITY AGENT WORKFLOW

1. **Step 1 (Plan):** Baca spesifikasi ini dan buat `task.md` berisi modul: `rendering_engine`, `controllers`, `column_layout`, `keyboard_interaction`, dan `export_utils`.
2. **Step 2 (Verify Constraints):** Pastikan tidak ada dependensi row pinning dan tidak ada serialization logic untuk column width.
3. **Step 3 (Implement):** Tulis kode dengan unit test komprehensif untuk `DualIndexMap` dan `FrameBatchThrottler`.