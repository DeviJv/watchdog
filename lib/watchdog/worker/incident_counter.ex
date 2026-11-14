defmodule Watchdog.Worker.IncidentCounter do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    Registry.register(Watchdog.PubSub, "alerts", [])
    Logger.info("IncidentCounter Siap Menghitung  ......")

    {:ok, %{}}
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_stats)
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:target_down, url, _reason}, state) do
    new_state = Map.update(state, url, 1, fn nilai_lama -> nilai_lama + 1 end)
    {:noreply, new_state}
  end

  def handle_info({:target_up, _url}, state) do
    {:noreply, state}
  end
end
