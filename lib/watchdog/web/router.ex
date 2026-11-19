defmodule Watchdog.Web.Router do
  alias Watchdog.Monitoring
  alias Watchdog.Controller.UrlController
  alias Watchdog.Worker.IncidentCounter
  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason
  )

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

  get "/api/status" do
    json_response =
      Monitoring.latest_status_per_url()
      |> Jason.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json_response)
  end

  get "/api/incidents" do
    json_response = IncidentCounter.get_state() |> Jason.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json_response)
  end

  post "/api/targets" do
    resp = UrlController.add_url(conn.body_params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(resp.status, resp.resp)
  end

  match(_) do
    send_resp(conn, 404, "{\"error\": \"Not Found\"}")
  end
end
