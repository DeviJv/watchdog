# 🐶 Watchdog — Distributed Real-Time Uptime & VM Telemetry Monitor

**Watchdog** adalah sistem pemantauan kesehatan (*uptime monitoring*) dan observabilitas mesin virtual berbasis **Elixir & OTP** yang dirancang dari nol tanpa *framework* web tingkat tinggi. Mengusung paradigma **"Functional Core, Imperative Shell"** serta **Domain-Driven Context Pattern**, aplikasi ini membuktikan ketangguhan arsitektur BEAM VM dalam menangani konkurensi, pemulihan kegagalan secara mandiri (*self-healing*), penyiaran data *real-time*, hingga komunikasi terdistribusi lintas *node* tanpa memerlukan perantara *message broker* eksternal.

---

## 🏗️ Arsitektur & Teknologi Inti OTP

Seluruh siklus hidup proses di dalam **Watchdog** diatur di bawah pohon pengawasan `Watchdog.Supervisor` dengan strategi `:one_for_one`, memastikan bahwa kegagalan pada satu komponen tidak akan meruntuhkan keseluruhan layanan. Di bagian pemrosesan inti, `Watchdog.Worker.Scheduler` bekerja secara periodik menggunakan `Process.send_after/3` dan mendelegasikan eksekusi HTTP *ping* secara paralel melalui `Task.Supervisor.async_stream/4` dengan batasan konkurensi serta isolasi *timeout*. Setiap hasil pengecekan divalidasi dan disimpan secara permanen ke dalam basis data **SQLite3** melalui lapisan fasad `Watchdog.Monitoring` (**Ecto Context**), memisahkan tanggung jawab persistensi data dari lapisan pekerja latar belakang.

Untuk memisahkan logika pemantauan jaringan dari logika pengiriman peringatan, **Watchdog** memanfaatkan `Registry` bawaan Elixir (`keys: :duplicate`) sebagai pusat *Pub/Sub message bus* internal. Ketika sebuah target terdeteksi gagal, *event* disiarkan ke `Watchdog.Worker.AlertWorker` yang menerapkan algoritma **Exponential Backoff** berbasis `:math.pow/2` guna mencegah *alert spam*, sekaligus memiliki mekanisme *auto-healing* untuk mereset status insiden saat target kembali pulih. Di sisi observabilitas, aplikasi ini diinstrumentasi menggunakan `:telemetry` untuk mencatat latensi setiap permintaan jaringan serta memantau konsumsi memori BEAM VM melalui `:erlang.memory()`.

Pada lapisan antarmuka publik, **Watchdog** ditenagai oleh server HTTP murni Elixir **Bandit** dan `Plug.Router` yang mengekspos berbagai *endpoint* JSON tervalidasi melalui `UrlValidator` dan `Jason`. Antarmuka pemantauan langsung (*Live Dashboard*) dibangun di atas protokol WebSocket menggunakan `WebSockAdapter` (`Watchdog.Web.SocketHandler`) yang terhubung langsung ke *Pub/Sub* internal, memungkinkan pembaruan status insiden dan metrik latensi di peramban secara instan tanpa muat ulang halaman. Lebih jauh lagi, arsitektur ini mendukung **Distributed Erlang Clustering** yang memungkinkan pemisahan peran *server* (`ROLE=api` dan `ROLE=worker`) dalam satu basis kode tunggal, di mana *node* API meneruskan perintah penambahan target secara dinamis melintasi batas jaringan ke *node* Worker menggunakan primitif `:rpc.call/4`.

```text
                       +-----------------------------------+
                       |        Watchdog.Supervisor        |
                       |         (strategy: :one_for_one)  |
                       +-----------------+-----------------+
                                         |
        +--------------------+-----------+-----------+--------------------+
        |                    |                       |                    |
        v                    v                       v                    v
+---------------+   +-----------------+   +-------------------+   +---------------+
|Watchdog.PubSub|   |  Watchdog.Repo  |   |  Task.Supervisor  |   | Bandit Server |
|  (Registry)   |   | (Ecto + SQLite) |   | (Concurrent Pool) |   | (HTTP + WS)   |
+-------+-------+   +--------+--------+   +---------+---------+   +-------+-------+
        ^                    ^                      ^                     |
        |                    |                      |                     v
        |           +--------+--------+             |            +----------------+
        +-----------+    Scheduler    +-------------+            |  Web.Router &  |
        |           |   (GenServer)   |                          | SocketHandler  |
        |           +-----------------+                          +----------------+
        |
        +----------> AlertWorker (Exponential Backoff & Auto-Healing)
        +----------> IncidentCounter (Stateful Event Aggregator)
```

---

## 📂 Struktur Proyek (Domain-Driven Contexts)

Basis kode **Watchdog** diorganisasikan berdasarkan batas domain bisnis (*Context Pattern*) daripada pengelompokan teknis MVC konvensional, memisahkan inti fungsional dari batas proses OTP dan lapisan antarmuka web:

```text
├── config/
│   └── config.exs                      # Konfigurasi daftar target URL awal & Ecto SQLite3
├── lib/
│   ├── watchdog.ex                     # Core HTTP Pinger & pengukuran durasi :timer.tc
│   └── watchdog/
│       ├── application.ex              # Entry point OTP & Role-Based Supervision Tree
│       ├── repo.ex                     # Ecto Repository (SQLite3 adapter)
│       ├── monitoring.ex               # Context fasad utama (Query DB & Cluster RPC dispatch)
│       ├── monitoring/
│       │   └── metric.ex               # Ecto Schema & Changeset validasi metrik
│       ├── rules/
│       │   └── url_validator.ex        # Validasi skema & format URL masuk
│       ├── worker/
│       │   ├── scheduler.ex            # GenServer penjadwal & Task.Supervisor dispatcher
│       │   ├── alert_worker.ex         # Subscriber Pub/Sub dengan Exponential Backoff & Auto-Healing
│       │   └── incident_counter.ex     # Aggregator penghitung total insiden per URL
│       └── web/
│           ├── router.ex               # Plug.Router untuk REST API, static UI, & WebSocket upgrade
│           ├── socket_handler.ex       # WebSockAdapter handler untuk live streaming ke browser
│           └── controllers/
│               └── url_controller.ex   # Controller HTTP untuk penambahan target dinamis
├── priv/
│   ├── repo/migrations/                # Skema DDL SQLite3 (tabel metrics & indeks URL)
│   └── static/
│       └── index.html                  # Live Real-Time Dashboard (WebSocket client)
└── test/                               # Rangkaian pengujian otomatis ExUnit
```

---

## ⚙️ Konfigurasi & Pemisahan Peran (Roles)

Konfigurasi statis aplikasi—seperti daftar target URL awal yang dipantau saat pertama kali berjalan serta pengaturan adaptor basis data Ecto SQLite3—didefinisikan secara terpusat di dalam berkas `config/config.exs`. Dengan menyimpan konfigurasi di luar kode sumber utama, daftar URL maupun berkas basis data antar lingkungan (*development*, *test*, maupun *production*) dapat disesuaikan tanpa perlu menyentuh logika bisnis aplikasi.

```elixir
config :watchdog, Watchdog.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "watchdog_#{config_env()}.db"

config :watchdog,
  urls: [
    "[https://github.com](https://github.com)",
    "[https://cloudflare.com](https://cloudflare.com)",
    "[https://microsoft.com](https://microsoft.com)"
  ]
```

Saat aplikasi dijalankan (*runtime*), `Watchdog.Application` membaca variabel lingkungan `ROLE` (dengan nilai bawaan `"all"`) dan `PORT` (dengan nilai bawaan `"4000"`) untuk menentukan topologi pohon pengawasan yang akan diaktifkan:

- **`ROLE=api`**: Hanya menyalakan infrastruktur bersama (`Watchdog.PubSub` dan `Watchdog.Repo`) beserta server web **Bandit** pada port yang ditentukan tanpa menjalankan *background pinger*, sehingga kapasitas CPU terfokus sepenuhnya untuk melayani permintaan HTTP dan koneksi WebSocket klien.
- **`ROLE=worker`**: Hanya mengaktifkan infrastruktur bersama dan seluruh pekerja latar belakang (`Task.Supervisor`, `Watchdog.Worker.Scheduler`, `Watchdog.Worker.AlertWorker`, dan `Watchdog.Worker.IncidentCounter`) tanpa membuka port HTTP eksternal.
- **`ROLE=all`** *(default)*: Menyalakan seluruh komponen API dan Worker secara bersamaan di dalam satu proses BEAM VM.

---

## 🚀 Cara Menjalankan Aplikasi

Sebelum menjalankan server dalam mode apa pun, pastikan seluruh dependensi Hex telah terunduh dan berkas basis data SQLite3 beserta skema tabelnya sudah dibuat dari direktori *root* proyek:

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
```

### 1. Mode Single Node (Pengembangan Lokal)

Untuk kebutuhan pengembangan lokal maupun pengujian terpadu dalam satu mesin, jalankan seluruh aplikasi sebagai satu kesatuan proses BEAM VM:

```bash
iex -S mix
```

Pada mode ini, `Watchdog.Application` otomatis menggunakan peran bawaan `ROLE=all` dan membuka layanan web pada `PORT=4000`:
- **Live Dashboard:** `http://localhost:4000/index.html`
- **REST API:** `http://localhost:4000/api/metrics`

### 2. Mode Distributed Cluster (`api@localhost` + `worker@localhost`)

Untuk mensimulasikan arsitektur produksi terdistribusi yang memisahkan beban kerja antara penerima trafik jaringan dan pemroses tugas latar belakang, jalankan aplikasi menggunakan dua sesi terminal terpisah dengan identitas *node* Erlang yang berbeda:

1. **Terminal 1 — Jalankan Node API (`api@localhost`)**  
   Fokus melayani lalu lintas HTTP REST API dan WebSocket pada port `4000` tanpa terbebani siklus *ping* latar belakang:
   ```bash
   ROLE=api PORT=4000 iex --sname api@localhost -S mix
   ```

2. **Terminal 2 — Jalankan Node Worker (`worker@localhost`)**  
   Fokus mengeksekusi penjadwalan *ping* konkuren, mencatat insiden, dan mengirimkan peringatan tanpa membuka port HTTP ke publik:
   ```bash
   ROLE=worker iex --sname worker@localhost -S mix
   ```

3. **Hubungkan Kedua Node menjadi Satu Cluster**  
   Dari dalam konsol interaktif Terminal 1 (`iex(api@localhost)1>`), sambungkan kedua mesin virtual Erlang menggunakan `Node.connect/1` hingga mengembalikan `true`, lalu verifikasi keanggotaan *cluster* melalui `Node.list/0`:
   ```elixir
   iex(api@localhost)1> Node.connect(:"worker@localhost")
   true

   iex(api@localhost)2> Node.list()
   [:worker@localhost]
   ```

4. **Kendalikan Worker Lintas Node via HTTP API (`:rpc.call/4`)**  
   Setelah kedua *node* terhubung, setiap permintaan penambahan target baru yang dikirim klien melalui `POST /api/targets` ke *node* API akan ditangkap oleh `Watchdog.Monitoring.add_target/1`, yang otomatis mendeteksi keberadaan *node* pekerja di `Node.list()` dan meneruskan eksekusi melintasi jaringan ke *node* Worker menggunakan `:rpc.call(worker_node, Watchdog.Worker.Scheduler, :add_target, [url])`:
   ```bash
   curl -X POST http://localhost:4000/api/targets \
     -H "Content-Type: application/json" \
     -d '{"url": "[https://elixir-lang.org](https://elixir-lang.org)"}'
   ```

---

## 📡 Daftar Endpoint HTTP & WebSocket

Seluruh layanan antarmuka publik **Watchdog** diekspos melalui `Watchdog.Web.Router` di atas server **Bandit** dengan pemisahan tanggung jawab antara penyajian antarmuka pengguna, aliran data *real-time*, dan operasi API berbasis JSON:

| Method | Endpoint | Deskripsi |
| :--- | :--- | :--- |
| `GET` | `/index.html` | Menyajikan halaman dasbor langsung (*Live UI*) berbasis HTML & JavaScript yang otomatis membuka koneksi WebSocket ke `/ws`. |
| `GET` | `/ws` | *Upgrade* protokol HTTP ke WebSocket (`WebSockAdapter` / `Watchdog.Web.SocketHandler`) untuk memancarkan pembaruan status *ping* secara instan dari *Pub/Sub* internal ke peramban klien. |
| `GET` | `/api/metrics` | Mengambil daftar 50 riwayat hasil *ping* terbaru dari basis data SQLite3. |
| `GET` | `/api/status` | Melihat kondisi kesehatan terakhir dari setiap URL unik yang dipantau. |
| `GET` | `/api/incidents` | Memeriksa ringkasan jumlah kegagalan (*incidents*) yang tercatat di memori `IncidentCounter`. |
| `POST` | `/api/targets` | Menerima *payload* JSON `{"url": "..."}`, memvalidasinya melalui `Watchdog.Rules.UrlValidator`, dan menyuntikkannya ke `Watchdog.Worker.Scheduler` secara dinamis (lokal maupun *remote worker node* via `:rpc.call/4`). |

---

## 🧪 Pengujian Otomatis

Seluruh rangkaian pengujian otomatis (*unit* dan *integration test*) menggunakan **ExUnit** dapat dijalankan dari direktori utama proyek melalui perintah:

```bash
mix test
```
