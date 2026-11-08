defmodule Watchdog.History do
  def get(url) do
    url
    |> lookup()
    |> format_response()
  end

  defp lookup(url) do
    :ets.lookup(:watchdog_metrics, url)
  end

  defp format_response([{_url, result}]) do
    result
  end

  defp format_response([]) do
    {:error, :not_found}
  end

  def all do
    :ets.tab2list(:watchdog_metrics)
  end
end
