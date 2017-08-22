# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :pastry_chef_test, PastryChefTest.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "eKOL5Lpg9yKVv1hDLAPHbCcTC40CRK8TUz2CiM6A7PQfHDeg9gNSZuiYa8n0QA5q",
  render_errors: [view: PastryChefTest.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PastryChefTest.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
