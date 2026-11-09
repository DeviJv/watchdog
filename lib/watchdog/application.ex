defmodule Watchdog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Watchdog.Worker.start_link(arg)
      #
      {Task.Supervisor, name: Watchdog.TaskSupervisor},
      {Watchdog.Scheduler, urls: Application.fetch_env!(:watchdog, :urls)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Watchdog.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
