defmodule Watchdog.SchedulerTest do
  use ExUnit.Case, async: false

  test "handle_info :ping_sekarang akan mengeksekusi ping dan menyimpan ke :ets" do
    # 1. SETUP: Bersihkan tabel ETS dari sisa test sebelumnya agar mulai dari nol
    :ets.delete_all_objects(:watchdog_metrics)

    # Pastikan ETS benar-benar kosong di awal
    assert length(Watchdog.History.all()) == 0

    # 2. ACT: Kirim pesan trigger ke proses Scheduler yang sedang berjalan
    # Ini mensimulasikan Process.send_after yang meledak/berbunyi
    send(Watchdog.Scheduler, :ping_sekarang)

    # 3. JEDA: Karena Scheduler melakukan request HTTP betulan ke internet
    # menggunakan async_stream, kita harus menidurkan proses test ini
    # selama 3 detik untuk menunggu respons dari website-website tersebut.
    Process.sleep(3000)

    # 4. ASSERT: Ambil semua data dari ETS menggunakan fungsi History.all()
    semua_data = Watchdog.History.all()

    # Cetak ke terminal biar kita bisa lihat isinya
    IO.puts("\n=== ISI ETS SETELAH PING ===")
    IO.inspect(semua_data)

    # Pastikan jumlah data di ETS lebih dari 0 (artinya ping sukses dan masuk memori)
    assert length(semua_data) > 0
  end

  test "add_target/1 menambahkan url baru ke dalam state GenServer" do
    # 1. SETUP: Siapkan URL baru yang mau ditambahkan
    url_baru = "https://kaskus.co.id"

    # 2. ACT: Panggil fungsi add_target/1
    Watchdog.Scheduler.add_target(url_baru)

    # 3. MENGINTIP STATE: Ambil state terbaru dari proses Scheduler
    # Karena name: __MODULE__, nama prosesnya adalah Watchdog.Scheduler
    state_sekarang = :sys.get_state(Watchdog.Scheduler)
    IO.inspect(state_sekarang)
    # 4. ASSERT: Pastikan url_baru ada di dalam state_sekarang (yang berupa List)
    # Hint: Anda bisa menggunakan `assert Enum.member?(list_nya, item_nya)`
    # ... KODE ANDA DI SINI ...

    assert Enum.member?(state_sekarang, url_baru)
  end
end
