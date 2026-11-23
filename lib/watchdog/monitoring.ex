defmodule Watchdog.Monitoring do
  alias Watchdog.Monitoring.Metric
  alias Watchdog.Repo

  import Ecto.Query, only: [from: 2]

  def list_metrics(limit \\ 50) do
    query =
      from(m in Metric,
        order_by: [desc: m.inserted_at, desc: m.id],
        limit: ^limit
      )

    Repo.all(query)
  end

  def latest_status_per_url() do
    latest_ids =
      from(m in Metric,
        group_by: m.url,
        select: max(m.id)
      )

    from(m in Metric,
      where: m.id in subquery(latest_ids),
      order_by: [desc: m.id]
    )
    |> Repo.all()
  end

  def create(attrs) do
    %Metric{}
    |> Metric.changeset(attrs)
    |> Repo.insert()
  end

  def add_target(url) when is_binary(url) do
    case Node.list() do
      [worker_node | _] ->
        case :rpc.call(worker_node, Watchdog.Worker.Scheduler, :add_target, [url]) do
          :ok -> {:ok, :worker}
          {:badrpc, reason} -> {:error, reason}
        end

      [] ->
        Watchdog.Worker.Scheduler.add_target(url)
        {:ok, :local}
    end
  end
end
