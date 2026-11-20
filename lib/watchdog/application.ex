defmodule Watchdog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Watchdog.Telemetry.attach()

    children = [
      # Starts a worker by calling: Watchdog.Worker.start_link(arg)

      {Registry, keys: :duplicate, name: Watchdog.PubSub},
      {Task.Supervisor, name: Watchdog.TaskSupervisor},
      {Watchdog.Repo, []},
      {Watchdog.Worker.Scheduler, urls: Application.fetch_env!(:watchdog, :urls)},
      {Watchdog.Worker.AlertWorker, []},
      {Watchdog.Worker.IncidentCounter, []},
      {Watchdog.Worker.MemoryMonitor, []},
      {Bandit, plug: Watchdog.Web.Router, port: 4000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Watchdog.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
