defmodule Watchdog.Web.SocketHandler do
  @behaviour WebSock
  require Logger

  @hearbeat_interval 30_000

  @impl true
  def init(state) do
    # 1. Daftarkan proses WebSocket ini ke Watchdog.PubSub (Registry.register/3)
    #    untuk mendengarkan topik yang sama dengan yang di-broadcast Scheduler!
    # 2. Kembalikan {:ok, state}
    Registry.register(Watchdog.PubSub, "metrics_live", [])
    Logger.info("Socket Handler Sedang Berjalan...")
    Process.send_after(self(), :hearbeat, @hearbeat_interval)
    {:ok, state}
  end

  @impl true
  def handle_in({_text, [opcode: :text]}, state) do
    # Wajib ada sesuai kontrak @behaviour WebSock (untuk menangkap pesan dari browser)

    {:ok, state}
  end

  @impl true
  def handle_info(:hearbeat, state) do
    Process.send_after(self(), :hearbeat, @hearbeat_interval)
    {:push, {:ping, ""}, state}
  end

  @impl true
  def handle_info({:new_metric, metric}, state) do
    # 1. Tangkap tuple event dari Registry (misal {:target_down, url, reason} / {:target_up, url}
    #    atau event metrik baru jika Anda ingin live stream setiap ping)
    # 2. Ubah menjadi Map lalu Jason.encode!/1
    # 3. Kembalikan {:push, {:text, json_string}, state}
    json_string = Jason.encode!(metric)
    {:push, {:text, json_string}, state}
  end

  def handle_info(_other, state) do
    {:ok, state}
  end
end
