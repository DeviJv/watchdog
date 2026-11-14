defmodule Watchdog.Worker.AlertWorkerTest do
  use ExUnit.Case, async: true

  setup do
    # 1. Bikin nama proses yang 100% unik khusus untuk tes ini
    process_name = :"alert_worker_test_#{System.unique_integer()}"

    # 2. Lahirkan AlertWorker terisolasi dengan nama unik tersebut
    pid = start_supervised!({Watchdog.Worker.AlertWorker, name: process_name})

    %{pid: pid}
  end

  test "mencatat failures dan menghitung delay saat menerima :target_down", %{pid: pid} do
    url = "https://kaskus.co.id"

    # 1. ACT: Lempar pesan ke worker
    send(pid, {:target_down, url, "timeout"})

    # 2. MENGINTIP STATE: Ambil state terbaru
    state_sekarang = :sys.get_state(pid)

    # 3. ASSERT: Pastikan URL masuk ke state dan failures bertambah
    # Hint: assert Map.has_key?(...), lalu cek nilai failures-nya
    # ... KODE ANDA DI SINI ...
    assert Map.has_key?(state_sekarang, url)
  end

  test "menghapus riwayat error saat menerima :target_up (Healing)", %{pid: pid} do
    url = "https://kaskus.co.id"

    # 1. SETUP: Bikin dia error dulu sekali
    send(pid, {:target_down, url, "timeout"})

    # Pastikan beneran masuk state sebelum disembuhkan
    assert Map.has_key?(:sys.get_state(pid), url)

    # 2. ACT: Kirim pesan kesembuhan
    send(pid, {:target_up, url})

    # 3. ASSERT: Pastikan state untuk URL tersebut sudah terhapus
    state_setelah_sembuh = :sys.get_state(pid)

    # Hint: assert ... == false atau refute Map.has_key?(...)
    # ... KODE ANDA DI SINI ...
    #
    assert Map.has_key?(state_setelah_sembuh, url) == false
  end
end
