defmodule DocumentPipeline.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DocumentPipelineWeb.Telemetry,
      DocumentPipeline.Repo,
      {DNSCluster, query: Application.get_env(:document_pipeline, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DocumentPipeline.PubSub},
      {Oban, Application.fetch_env!(:document_pipeline, Oban)},
      # Start a worker by calling: DocumentPipeline.Worker.start_link(arg)
      # {DocumentPipeline.Worker, arg},
      # Start to serve requests, typically the last entry
      DocumentPipelineWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DocumentPipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DocumentPipelineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
