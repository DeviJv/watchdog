defmodule Watchdog.SchedulerTest do
  require Logger
  use ExUnit.Case, async: true

  # Blok setup akan dijalankan sebelum setiap blok `test` di bawahnya.
  setup do
    # 1. Bikin nama unik untuk tabel dan proses khusus untuk tes ini saja
    # (Trik industri agar async test tidak tabrakan)
    ets_table = :"test_table_#{System.unique_integer()}"
    process_name = :"test_process_#{System.unique_integer()}"

    # 2. Lahirkan Scheduler baru yang terisolasi HANYA untuk tes ini
    # Ini tidak akan mengganggu Scheduler utama dari application.ex
    start_supervised!({
      Watchdog.Scheduler,
      urls: ["https://example.com"], ets_table: ets_table, name: process_name
    })

    # 3. Lempar nama proses dan tabel ke dalam context agar bisa dipakai di blok test
    %{pid_name: process_name, table: ets_table}
  end

  test "add_target/1 menambahkan url baru ke dalam state GenServer", %{pid_name: pid} do
    url_baru = "https://kaskus.co.id"

    # Gunakan pid/nama dinamis untuk menggantikan nama global Watchdog.Scheduler
    GenServer.cast(pid, {:tambah_url, url_baru})

    state_sekarang = :sys.get_state(pid)

    # State sekarang adalah Map! Jadi kita harus cek di dalam key :urls
    Logger.debug(state_sekarang)
    assert Enum.member?(state_sekarang.urls, url_baru)
  end
end
