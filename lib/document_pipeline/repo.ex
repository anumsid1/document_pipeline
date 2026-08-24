defmodule DocumentPipeline.Repo do
  use Ecto.Repo,
    otp_app: :document_pipeline,
    adapter: Ecto.Adapters.Postgres
end
