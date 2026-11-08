defmodule Watchdog.History do
  def get(url) do
    url
    |> lookup()
    |> format_response()
  end

  defp lookup(url) do
    :ets.lookup(:watchdog_metrics, url)
  end

  def format_response([{_url, result}]) do
    result
  end

  def format_response([]) do
    {:error, :not_found}
  end
end
