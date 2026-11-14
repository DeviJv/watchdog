defmodule Watchdog.Worker.MemoryMonitor do
  use GenServer

  @interval 300_000
  @bytes_per_mb 1_048_576

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    :application.ensure_all_started(:os_mon)

    Process.send_after(self(), :cek_memory, 1_000)
    {:ok, %{}}
  end

  def handle_info(:cek_memory, state) do
    vm_mem = :erlang.memory()
    os_mem = :memsup.get_system_memory_data()

    vm_total_mb = (Keyword.get(vm_mem, :total, 0) / @bytes_per_mb) |> Float.round(2)
    vm_ets_mb = (Keyword.get(vm_mem, :ets, 0) / @bytes_per_mb) |> Float.round(2)
    os_total_mb = (Keyword.get(os_mem, :total_memory, 0) / @bytes_per_mb) |> Float.round(2)
    os_free_mb = (Keyword.get(os_mem, :free_memory, 0) / @bytes_per_mb) |> Float.round(2)

    :telemetry.execute(
      [:watchdog, :system, :memory],
      %{
        vm_total_mb: vm_total_mb,
        vm_ets_mb: vm_ets_mb,
        os_total_mb: os_total_mb,
        os_free_mb: os_free_mb
      },
      %{node: node()}
    )

    Process.send_after(self(), :cek_memory, @interval)

    {:noreply, state}
  end
end
