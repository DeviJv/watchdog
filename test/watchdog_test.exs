defmodule WatchdogTest do
  use ExUnit.Case, async: true

  # Setup dijalankan sebelum setiap blok 'test' dimulai
  setup do
    # Menyalakan web server bohongan di port acak
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "ping/1 mengembalikan status 200 saat server merespons sukses", %{bypass: bypass} do
    # 1. Konfigurasi server bohongan agar selalu membalas dengan HTTP 200
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "OK")
    end)

    # 2. Ambil URL lokal dari server bohongan tersebut (contoh: http://localhost:12345)
    url_bohongan = "http://localhost:#{bypass.port}"

    # 3. Tembak menggunakan fungsi ping() Anda
    # Kita menggunakan Pattern Matching ketat untuk memvalidasi kembaliannya
    assert {:ok, %{status: 200, time_in_ms: time}} = Watchdog.ping(url_bohongan)

    # Validasi tambahan: waktu respons tidak boleh minus
    assert time >= 0
  end

  test "ping/1 menangani error saat server down", %{bypass: bypass} do
    # 1. Konfigurasi server bohongan untuk memutus koneksi secara paksa (Simulasi server mati)
    Bypass.down(bypass)

    url_bohongan = "http://localhost:#{bypass.port}"

    # 2. Fungsi ping Anda harus mengembalikan tuple :error jika target mati
    assert {:error, _reason} = Watchdog.ping(url_bohongan)
  end
end
