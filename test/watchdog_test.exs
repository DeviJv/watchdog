defmodule WatchdogTest do
  use ExUnit.Case, async: true
  doctest Watchdog

  test "greets the world" do
    assert Watchdog.hello() == :world
  end

  describe "ping/1" do
    # scenario berhasil
    test "returns :ok and status: 200 for a valid URL" do
      # siapkan URL pasti yang hidup
      url = "https://httpbin.org/status/200"
      # jalankan fungsi yg akan di exekusi
      {status, resp} = Watchdog.ping(url)
      # pasti hasil yang kita harapkan
      assert status == :ok
      assert resp.status == 200
      assert resp.url == url

      # Kita juga bisa memastikan time_in_ms adalah sebuah angka (float)
      assert is_float(resp.time_in_ms)
    end

    # scenario gagal
    test "return :error kalo url nya ga valid atau asal" do
      # siapkan url ngasal
      url = "https://ini-pasti-ga-ada-web-nya.xxw"

      # jalankan fungsi yang akan di exekusi
      {status, resp} = Watchdog.ping(url)

      # Pastikan (Assert) aplikasi tidak crash, melainkan mengembalikan :error
      assert status == :error

      # pastikan ada pesan error di dalam map
      assert Map.has_key?(resp, :reason)
      assert resp.url == url
    end
  end
end
