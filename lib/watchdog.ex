defmodule Watchdog do
  @moduledoc """
  Documentation for `Watchdog`.
  """
  @headers [
    {"user-agent",
     "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"},
    {"accept",
     "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"},
    {"accept-language", "en-US,en;q=0.9"},
    {"sec-ch-ua", "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\""},
    {"sec-ch-ua-mobile", "?0"},
    {"sec-ch-ua-platform", "\"Windows\""},
    {"sec-fetch-dest", "document"},
    {"sec-fetch-mode", "navigate"},
    {"sec-fetch-site", "none"},
    {"sec-fetch-user", "?1"},
    {"upgrade-insecure-requests", "1"}
  ]

  @doc """
  Hello world.

  ## Examples

      iex> Watchdog.hello()
      :world

  """
  def hello do
    :world
  end

  # memasukan URL dengan format string kedalam function nya
  def ping(url) do
    url
    |> build_request
    |> execute_and_measure(url)
    |> format_response()
  end

  # tambahkan headers supaya ga di sangka bot dan kena RTO soal nya kalo dia ga di tambah dia memang otomatis get lagi
  # tapi aga jadi tambah lama
  # return dari Req.get di bawah ada selalu ada 2 tuple yaitu {:ok, resp} atau {:error, reason}
  defp build_request(url) do
    fn -> Req.get(url, headers: @headers, retry: false) end
  end

  defp execute_and_measure(fun, url) do
    # mengukur seberapa lama fun berjalan
    {time_in_us, result} = :timer.tc(fun)
    # convert ke milisecond
    time_in_ms = time_in_us / 1_000
    # return berlanjut ke kebutuhan selanjut nya
    {result, time_in_ms, url}
  end

  defp format_response({{:ok, resp}, time_in_ms, url}) do
    {:ok, %{url: url, status: resp.status, time_in_ms: time_in_ms}}
  end

  defp format_response({{:error, exception}, time_in_ms, url}) do
    {:error, %{url: url, reason: Exception.message(exception), time_in_ms: time_in_ms}}
  end

  # di bawah works juga pakai case
  # tapi jika ingin lebih elixir way idiomatic dari ke unggulan pattern matching nya
  # kita bisa pakai fungsi dengan pattern matching seperti di atas

  #   defp building_result({result, time_in_ms, url}) do
  #     case result do
  #       # jika success atau :ok simpan di resp
  #       # response harus ada :ok dan error supaya bisa di pakai di test unit
  #       {:ok, resp} ->
  #         {:ok, %{url: url, status: resp.status, time_in_ms: time_in_ms}}
  #
  #       # kalo error
  #       {:error, exception} ->
  #         {:error, %{url: url, reason: Exception.message(exception), time_in_ms: time_in_ms}}
  #     end
  #   end
end
