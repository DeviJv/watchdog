defmodule Watchdog.Worker.AlertWorker do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    # Mendaftarkan diri ke kantor pos untuk mendengarkan topik "alerts"
    Registry.register(Watchdog.PubSub, "alerts", [])
    Logger.info("AlertWorker bersiap mendengarkan insiden...")

    {:ok, %{}}
  end

  # Menangkap event dari Scheduler
  def handle_info({:target_down, url, reason}, state) do
    now = :os.system_time(:second)
    catatan_url = Map.get(state, url, %{failures: 0, next_alert_at: 0})
    # 2. EVALUASI: Boleh teriak atau tidak?
    if now >= catatan_url.next_alert_at do
      # --- MASUKKAN LOGIKA ANDA DI SINI NANTI MALAM ---
      # a. Cetak peringatan (Logger.warning)
      # b. Hitung failures baru (catatan_url.failures + 1)
      # c. Hitung waktu penundaan pakai :math.pow
      # d. Tentukan jadwal next_alert_at
      # e. Simpan kembali data tersebut ke state menggunakan Map.put(state, url, catatan_baru)
      # f. Return {:noreply, state_baru}
      Logger.warning("🚨 PERINGATAN! Website target DOWN: #{url}. Alasan: #{inspect(reason)}")
      new_failures = catatan_url.failures + 1
      delay_seconds = round(:math.pow(5, new_failures))
      next_alert_at = now + delay_seconds
      catatan_baru = %{failures: new_failures, next_alert_at: next_alert_at}
      state_baru = Map.put(state, url, catatan_baru)
      {:noreply, state_baru}
    else
      # Jika belum waktunya teriak, diam saja dan kembalikan state lama tanpa diubah
      {:noreply, state}
    end
  end

  def handle_info({:target_up, url}, state) do
    # Cek apakah URL tersebut ada di buku catatan error kita
    if Map.has_key?(state, url) do
      Logger.notice("✅ Website UP kembali: #{url}")
      new_state = Map.delete(state, url)
      {:noreply, new_state}
    else
      # Jika dari awal memang sehat, diam saja agar tidak spamming
      {:noreply, state}
    end
  end
end
