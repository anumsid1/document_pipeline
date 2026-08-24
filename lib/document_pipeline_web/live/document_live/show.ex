defmodule DocumentPipelineWeb.DocumentLive.Show do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Document {@document.id}
        <:subtitle>This is a document record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/documents"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/documents/#{@document}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit document
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Filename">{@document.filename}</:item>
        <:item title="Content type">{@document.content_type}</:item>
        <:item title="Storage path">{@document.storage_path}</:item>
        <:item title="File size">{@document.file_size}</:item>
        <:item title="Domain type">{@document.domain_type}</:item>
        <:item title="Domain type source">{@document.domain_type_source}</:item>
        <:item title="Status">{@document.status}</:item>
        <:item title="Raw text">{@document.raw_text}</:item>
        <:item title="Page count">{@document.page_count}</:item>
        <:item title="Error message">{@document.error_message}</:item>
        <:item title="Processing started at">{@document.processing_started_at}</:item>
        <:item title="Processing completed at">{@document.processing_completed_at}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Documents.get_document(id) do
      {:ok, document} ->
        {:ok,
         socket
         |> assign(:page_title, "Show Document")
         |> assign(:document, document)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Document not found")
         |> push_navigate(to: ~p"/documents")}
    end
  end
end
