import Config

config :watchdog, Watchdog.Repo,
  database: "watchdog_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

# Beri tahu Ecto letak repo kita
config :watchdog, ecto_repos: [Watchdog.Repo]

config :watchdog,
  urls: [
    "https://tohtemunc12321.c11om",
    "https://github.com",
    "https://cloudflare.com"
    # "https://microsoft.com",
    # "https://apple.com",
    # "https://wikipedia.org",
    # "https://amazon.com",
    # "https://news.ycombinator.com",
    # "https://reddit.com",
    # "https://netflix.com",
    # "https://yahoo.com"
  ]

# tambah baru kalo butuh

# Optional: import environment-specific files like dev.exs, test.exs, or prod.exs
# import_config "#{config_env()}.exs"
