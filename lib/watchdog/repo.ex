defmodule Watchdog.Repo do
  use Ecto.Repo,
    otp_app: :watchdog,
    adapter: Ecto.Adapters.SQLite3
end
