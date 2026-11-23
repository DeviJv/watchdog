defmodule Watchdog.Web.Controller.UrlController do
  alias Watchdog.Monitoring
  alias Watchdog.Rules.UrlValidator

  def add_url(%{"url" => url}) do
    case UrlValidator.validate_url(url) do
      {:ok, valid_url} ->
        case Monitoring.add_target(valid_url) do
          {:ok, node_target} ->
            response =
              %{
                status: "created",
                message: "Target added to scheduler (#{node_target})",
                url: valid_url
              }
              |> Jason.encode!()

            %{status: 201, resp: response}

          {:error, reason} ->
            error_response =
              %{error: "Gagal menghubungi worker node: #{inspect(reason)}"}
              |> Jason.encode!()

            %{status: 502, resp: error_response}
        end

      {:error, pesan_error} ->
        error_response =
          %{error: pesan_error}
          |> Jason.encode!()

        %{status: 422, resp: error_response}
    end
  end

  def add_url(_) do
    error_response =
      %{error: "Field 'url' wajib diisi dan berupa string"}
      |> Jason.encode!()

    %{status: 400, resp: error_response}
  end
end
