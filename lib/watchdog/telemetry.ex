defmodule Watchdog.Telemetry do
  require Logger

  # Fungsi ini akan dipanggil di application.ex nanti
  def attach() do
    # Mendaftarkan fungsi handle_event ke event [:watchdog, :pinger, :request]

    :telemetry.attach_many(
      "watchdog-metrics-handler",
      [
        [:watchdog, :pinger, :request],
        [:watchdog, :system, :memory]
      ],
      &__MODULE__.handle_event/4,
      nil
    )

    Logger.info("Telemetry Pinger Logger Attached!")
  end

  # Fungsi ini otomatis tereksekusi setiap kali Req.get selesai
  def handle_event([:watchdog, :pinger, :request], measurements, metadata, _config) do
    # TUGAS ANDA: Cetak log yang rapi.
    # Contoh: [METRIK] URL: https://google.com | Latensi: 145.5 ms
    Logger.info("[METRIK] Request selesai",
      url: metadata.url,
      duration_ms: measurements.duration_ms
    )
  end

  def handle_event([:watchdog, :system, :memory], measurements, _metadata, _config) do
    Logger.info(
      "[MEMORY] VM Total: #{measurements.vm_total_mb} MB | ETS: #{measurements.vm_ets_mb} MB | OS Free: #{measurements.os_free_mb}/#{measurements.os_total_mb} MB"
    )
  end
end
