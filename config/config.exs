use Mix.Config

config :redis_test,
  # Path to the docker-compose.yml file to start
  divo: "test/support/docker-compose.yml",

  # Divo options for health checks, set
  divo_wait: [dwell: 700, max_tries: 50]
