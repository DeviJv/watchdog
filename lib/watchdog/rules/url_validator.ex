defmodule Watchdog.Rules.UrlValidator do
  # 1. Cek jika input BUKAN string
  def validate_url(url) when not is_binary(url) do
    {:error, "Input harus berupa teks (string)"}
  end

  # 2. Cek struktur URL jika input adalah string
  def validate_url(url) do
    case URI.new(url) do
      # Jika valid (https dan punya host yang bertitik)
      {:ok, %URI{scheme: "https", host: host}} when is_binary(host) ->
        if valid_domain?(host) do
          {:ok, url}
        else
          {:error, "Domain tidak valid, harus mengandung titik (contoh: domain.com)"}
        end

      # Jika protokolnya bukan https (misal: http://)
      {:ok, %URI{scheme: scheme}} when scheme != "https" ->
        {:error, "URL wajib menggunakan protokol https://"}

      # Jika format URL berantakan / gagal di-parse
      _ ->
        {:error, "Format URL tidak valid"}
    end
  end

  # Fungsi bantuan untuk cek titik pada domain
  defp valid_domain?(host) do
    String.contains?(host, ".") and
      not String.starts_with?(host, ".") and
      not String.ends_with?(host, ".")
  end
end
