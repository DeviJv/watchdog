defmodule Watchdog.HistoryTest do
  # Gunakan async: false karena ETS table :watchdog_metrics digunakan secara global
  use ExUnit.Case, async: false

  describe "get/1" do
    test "mengembalikan hasil ping jika URL ada di memori" do
      # 1. SETUP: Siapkan URL dan data palsu (mock data)
      url = "https://test-web-palsu.com"
      data_palsu = {:ok, %{status: 200, time_in_ms: 150.5}}

      # 2. INJECT: Masukkan data palsu tersebut secara manual ke :ets
      # Hint: Gunakan fungsi Erlang :ets.insert/2 seperti di Scheduler
      # ... KODE ANDA DI SINI ...
      :ets.insert(:watchdog_metrics, {url, data_palsu})

      # 3. ACT: Panggil fungsi get/1 yang mau kita test
      hasil = Watchdog.History.get(url)

      # 4. ASSERT: Pastikan hasilnya sesuai dengan ekspektasi
      # Hint: assert hasil == data_palsu
      # ... KODE ANDA DI SINI ...
      assert hasil == data_palsu
    end

    test "mengembalikan error not_found jika URL tidak ada" do
      url = "https://web-ga-pernah-ada.com"

      # ACT: Langsung panggil fungsi get/1
      hasil = Watchdog.History.get(url)

      # ASSERT: Pastikan hasilnya {:error, :not_found}
      # ... KODE ANDA DI SINI ...
      assert hasil == {:error, :not_found}
    end
  end
end
