import Config

config :watchdog,
  urls: [
    "https://github.com",
    "https://cloudflare.com",
    "https://microsoft.com",
    "https://apple.com",
    "https://wikipedia.org",
    "https://amazon.com",
    "https://news.ycombinator.com",
    "https://reddit.com",
    "https://netflix.com",
    "https://yahoo.com"
  ]

# tambah baru kalo butuh

# Optional: import environment-specific files like dev.exs, test.exs, or prod.exs
# import_config "#{config_env()}.exs"
