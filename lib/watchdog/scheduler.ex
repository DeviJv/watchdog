defmodule Watchdog.Scheduler do
  require Logger
  use GenServer
  @ping_interval 5_000
  @sleep_interval 1_000
  @max_concurrency 4
  @timeout_concurrency 10_000

  def start_link(opts \\ []) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`

    Logger.info("Starting SchedulerServer .....")
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    # Ambil urls dan ets_table dari opts, wajib pakai pattern Keyword List

    urls = Keyword.get(opts, :urls, [])
    ets_table = Keyword.get(opts, :ets_table, :watchdog_metrics)
    # Bikin tabel memori bernama :watchdog_metrics
    # :set artinya tipe datanya unik (key-value), :public agar bisa ditulis oleh Task worker dan dia create or update
    # jadi tidak menumpuk atau duplicate dengan url menjadi primary key nya
    # kalo primary sudah ada dia akan update hasil nya saja ketika insert di bawah
    # :named_table agar kita bisa memanggilnya cukup dengan nama :watchdog_metrics

    :ets.new(ets_table, [:set, :public, :named_table])

    Process.send_after(self(), :ping_sekarang, @sleep_interval)

    {:ok, %{urls: urls, ets_table: ets_table}}
  end

  def add_target(url) do
    GenServer.cast(__MODULE__, {:tambah_url, url})
  end

  def handle_cast({:tambah_url, new_url}, state) do
    new_urls = [new_url | state.urls]
    {:noreply, %{state | urls: new_urls}}
  end

  def handle_info(:ping_sekarang, state) do
    Logger.info("Mengecek jumlah url : #{length(state.urls)}")

    # gunakan ini sebagai pengganti enum.each lalu kita bisa buat dia conccurency juga dengan
    # async_stream dengan batasan poll concurrency yaitu 4

    Task.Supervisor.async_stream(
      Watchdog.TaskSupervisor,
      state.urls,
      fn url -> ping(url, state.ets_table) end,
      # Maksimal 4 proses jalan berbarengan
      max_concurrency: @max_concurrency,
      timeout: @timeout_concurrency,
      on_timeout: :kill_task
    )
    |> Stream.run()

    # pasang lagi alarm selama 5 detik kedepan karna looping tak terbatas
    Process.send_after(self(), :ping_sekarang, @ping_interval)

    # Kembalikan state seperti semua (jangan lupa ini wajib di handle info)
    {:noreply, state}
  end

  defp ping(url, ets_table) do
    # Lakukan ping dan insert ke :ets di sini (sama seperti sebelumnya)
    hasil = Watchdog.ping(url)

    # simpan hasil ke memory ETS!
    :ets.insert(ets_table, {url, hasil})

    Logger.debug("Hasil Ping : #{inspect(hasil)}")
  end
end
