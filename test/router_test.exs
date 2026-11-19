defmodule Watchdog.RouterTest do
  # require Logger
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias Watchdog.Web.Router

  @opts Router.init([])

  describe "GET Endpoint" do
    test "GET api/status mengembalikan 200 ok dan list JSON" do
      conn = conn(:get, "/api/status") |> Router.call(@opts)
      assert conn.status == 200
      assert is_list(Jason.decode!(conn.resp_body))
    end

    test "GET api/api/metrics Mengembalika 200 ok dan list json" do
      conn = conn(:get, "/api/metrics") |> Router.call(@opts)
      assert conn.status == 200
      assert is_list(Jason.decode!(conn.resp_body))
    end

    test "GET api/incidents Mengembalika 200 ok dan list json" do
      conn = conn(:get, "/api/incidents") |> Router.call(@opts)
      assert conn.status == 200
      assert is_map(Jason.decode!(conn.resp_body))
    end
  end

  describe "POST /api/targets" do
    # Tambahkan 3 skenario test:
    # 1. Valid HTTPS URL -> status 201
    #
    test "POST api/api/targets Valid HTTPS URL -> status 201" do
      payload = Jason.encode!(%{url: "https://elixir-lang.org"})

      conn =
        conn(:post, "/api/targets", payload)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["status"] == "created"
      assert body["url"] == "https://elixir-lang.org"
    end

    test "mengembalikan 422 Unprocessable Entity jika URL tidak valid" do
      payload = Jason.encode!(%{url: "http://bukan-https.com"})

      conn =
        conn(:post, "/api/targets", payload)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 422
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body, "error")
    end

    test "mengembalikan 400 Bad Request jika field url tidak dikirim" do
      payload = Jason.encode!(%{})

      conn =
        conn(:post, "/api/targets", payload)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body, "error")
    end

    test "mengembalikan 422 Bad Request jika field url bukan string" do
      payload = Jason.encode!(%{url: 123_123})

      conn =
        conn(:post, "/api/targets", payload)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 422
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body, "error")
    end
  end

  test "Route tidak di kenal atau 404 not found" do
    conn = conn(:get, "/api/15125122512") |> Router.call(@opts)
    assert conn.status == 404
  end
end
