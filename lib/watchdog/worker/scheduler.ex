defmodule Watchdog.Worker.Scheduler do
  use GenServer
  require Logger

  alias Watchdog.Monitoring
  alias Watchdog.Monitoring.Metric

  @ping_interval 5_000
  @sleep_interval 1_000
  @max_concurrency 4
  @timeout_concurrency 15_000

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

    Process.send_after(self(), :ping_sekarang, @sleep_interval)

    {:ok, %{urls: urls}}
  end

  def add_target(url) do
    GenServer.cast(__MODULE__, {:tambah_url, url})
  end

  def handle_cast({:tambah_url, new_url}, state) do
    if(Enum.member?(state.urls, new_url)) do
      {:noreply, state}
    else
      new_urls = [new_url | state.urls]
      {:noreply, %{state | urls: new_urls}}
    end
  end

  def handle_info(:ping_sekarang, state) do
    Logger.info("Mengecek jumlah url : #{length(state.urls)}")

    # gunakan ini sebagai pengganti enum.each lalu kita bisa buat dia conccurency juga dengan
    # async_stream dengan batasan poll concurrency yaitu 4

    Task.Supervisor.async_stream(
      Watchdog.TaskSupervisor,
      state.urls,
      &ping/1,
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

  defp ping(url) do
    # Lakukan ping dan insert ke :ets di sini (sama seperti sebelumnya)
    case Watchdog.ping(url) do
      {:ok, %{status: status, time_in_ms: raw_time}} ->
        # Jika server hidup tapi merespons dengan kode error (misal 500 Server Error)
        if status >= 400 do
          broadcast_alert(url, "HTTP Status Error: #{status}")
        else
          broadcast_up(url)
        end

        %{
          url: url,
          status_code: status,
          time_ms: round(raw_time),
          error_reason: nil
        }
        |> simpan_ke_db()

      {:error, reason} ->
        # [JAWABAN TUGAS 3 ADA DI SINI]
        # Berteriak ke Registry bahwa target mati, sebelum data disimpan ke DB.
        broadcast_alert(url, inspect(reason))

        %{
          url: url,
          status_code: nil,
          # Atau bisa diset default
          time_ms: 0,
          # Ubah error menjadi string
          error_reason: inspect(reason)
        }
        |> simpan_ke_db()
    end
  end

  # Alih-alih pakai case, kita lempar langsung ke fungsi multiclause
  defp simpan_ke_db(attrs) do
    attrs
    |> Monitoring.create()
    |> handle_db_result
  end

  # Function head 1: Menangkap jika sukses
  defp handle_db_result({:ok, %Metric{} = metric}) do
    Logger.debug("Berhasil simpan data ping ke DB: #{metric.url}")
    # panggil broadcast_metric()
    broadcast_metric(metric)
  end

  # Function head 2: Menangkap jika gagal (error changeset)
  defp handle_db_result({:error, %Ecto.Changeset{} = changeset}) do
    Logger.error("Gagal simpan ke DB: #{inspect(changeset.errors)}")
  end

  defp broadcast_metric(metric) do
    Registry.dispatch(Watchdog.PubSub, "metrics_live", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:new_metric, metric})
    end)
  end

  defp broadcast_alert(url, reason) do
    Registry.dispatch(Watchdog.PubSub, "alerts", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:target_down, url, reason})
    end)
  end

  defp broadcast_up(url) do
    Registry.dispatch(Watchdog.PubSub, "alerts", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:target_up, url})
    end)
  end
end
