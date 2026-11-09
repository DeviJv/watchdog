defmodule Watchdog.MetricContext do
  alias Watchdog.Metric
  alias Watchdog.Repo

  def list_metrics() do
    Repo.all(Metric)
  end

  def create(attrs) do
    %Metric{}
    |> Metric.changeset(attrs)
    |> Repo.insert()
  end
end
