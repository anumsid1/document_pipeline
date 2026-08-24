defmodule DocumentPipelineWeb.DocumentFieldLive.Show do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Document field {@document_field.id}
        <:subtitle>This is a document_field record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/document_fields"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/document_fields/#{@document_field}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit document_field
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Field name">{@document_field.field_name}</:item>
        <:item title="Field value">{@document_field.field_value}</:item>
        <:item title="Confidence">{@document_field.confidence}</:item>
        <:item title="Source">{@document_field.source}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Document field")
     |> assign(:document_field, Documents.get_document_field!(id))}
  end
end
