defmodule Watchdog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    role = System.get_env("ROLE") || "all"

    base_children = [
      {Registry, keys: :duplicate, name: Watchdog.PubSub},
      {Watchdog.Repo, []}
    ]

    port = String.to_integer(System.get_env("PORT") || "4000")

    role_children =
      case role do
        "api" ->
          [
            {Bandit, plug: Watchdog.Web.Router, port: port}
          ]

        "worker" ->
          [
            {Task.Supervisor, name: Watchdog.TaskSupervisor},
            {Watchdog.Worker.Scheduler, urls: Application.fetch_env!(:watchdog, :urls)},
            {Watchdog.Worker.AlertWorker, []},
            {Watchdog.Worker.IncidentCounter, []},
            {Watchdog.Worker.MemoryMonitor, []}
          ]

        _ ->
          [
            {Task.Supervisor, name: Watchdog.TaskSupervisor},
            {Watchdog.Worker.AlertWorker, []},
            {Watchdog.Worker.IncidentCounter, []},
            {Watchdog.Worker.Scheduler, urls: Application.fetch_env!(:watchdog, :urls)},
            {Bandit, plug: Watchdog.Web.Router, port: port},
            {Watchdog.Worker.MemoryMonitor, []}
          ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Watchdog.Supervisor]
    Supervisor.start_link(base_children ++ role_children, opts)
  end
end
