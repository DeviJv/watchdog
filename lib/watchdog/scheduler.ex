defmodule Watchdog.Scheduler do
  use GenServer

  def start_link(init_args \\ []) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    #
    IO.puts("Starting SchedulerServer .....")

    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(urls) do
    # Bikin tabel memori bernama :watchdog_metrics
    # :set artinya tipe datanya unik (key-value), :public agar bisa ditulis oleh Task worker
    # :named_table agar kita bisa memanggilnya cukup dengan nama :watchdog_metrics
    :ets.new(:watchdog_metrics, [:set, :public, :named_table])
    # tambahan panggil default url
    default_url = default_url()
    new_urls = urls ++ default_url

    Process.send_after(self(), :ping_sekarang, 1_000)

    {:ok, new_urls}
  end

  def add_target(url) do
    GenServer.cast(__MODULE__, {:tambah_url, url})
  end

  def handle_cast({:tambah_url, new_url}, urls) do
    new_urls = [new_url | urls]
    {:noreply, new_urls}
  end

  def handle_info(:ping_sekarang, urls) do
    IO.puts("Mengecek jumlah url : #{length(urls)}")

    # gunakan ini sebagai pengganti enum.each lalu kita bisa buat dia conccurency juga dengan
    # async_stream dengan batasan poll concurrency yaitu 2

    Task.Supervisor.async_stream(
      Watchdog.TaskSupervisor,
      urls,
      fn url ->
        hasil = Watchdog.ping(url)

        # simpan hasil ke memory ETS!
        :ets.insert(:watchdog_metrics, {url, hasil})

        IO.inspect(hasil, label: "Hasil Ping")
        # Lakukan ping dan insert ke :ets di sini (sama seperti sebelumnya)
      end,
      # Maksimal 2 proses jalan berbarengan
      max_concurrency: 4
    )
    |> Stream.run()

    # looping setiap URL yg masuk
    #     Enum.each(urls, fn url ->
    #       Task.Supervisor.start_child(Watchdog.TaskSupervisor, fn ->
    #         # lakukan ping secara bersamaan
    #         hasil = Watchdog.ping(url)
    #
    #         # simpan hasil ke memory ETS!
    #         :ets.insert(:watchdog_metrics, {url, hasil})
    #
    #         IO.inspect(hasil, label: "Hasil Ping")
    #       end)
    #     end)

    # pasang lagi alarm selama 5 detik kedepan karna looping tak terbatas
    Process.send_after(self(), :ping_sekarang, 5_000)

    # Kembalikan state seperti semua (jangan lupa ini wajib di handle info)
    {:noreply, urls}
  end

  def default_url() do
    ["https://google.com", "https://youtube.com"]
  end
end
