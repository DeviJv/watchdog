defmodule Watchdog.Web.Router do
  alias Watchdog.Monitoring
  use Plug.Router

  plug(:match)
  # Middleware agar Plug Tahu kita mengirim json

  plug(:dispatch)

  get "/api/metrics" do
    json_response =
      Monitoring.list_metrics()
      |> Jason.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json_response)
  end

  match(_) do
    send_resp(conn, 404, "{\"error\": \"Not Found\"}")
  end
end
