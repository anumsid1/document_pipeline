import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :document_pipeline, DocumentPipeline.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "document_pipeline_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :document_pipeline, DocumentPipelineWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "q6vd2uEJej4fj6go1ghpMOwlyr/kLqgX3JVRM4k56y8zPvx1ISVEZ3XnJ6Mfe9bT",
  server: false

# In test we don't send emails
config :document_pipeline, DocumentPipeline.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :document_pipeline, Oban, testing: :manual

config :document_pipeline,
  classifier_adapter: DocumentPipeline.AI.Classifier.MockAdapter,
  extractor_adapter: DocumentPipeline.AI.Extractor.MockAdapter
