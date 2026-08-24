defmodule DocumentPipelineWeb.DocumentLive.Index do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Documents
        <:actions>
          <.button variant="primary" navigate={~p"/documents/new"}>
            <.icon name="hero-plus" /> New Document
          </.button>
        </:actions>
      </.header>

      <.table
        id="documents"
        rows={@streams.documents}
        row_click={fn {_id, document} -> JS.navigate(~p"/documents/#{document}") end}
      >
        <:col :let={{_id, document}} label="Filename">{document.filename}</:col>
        <:col :let={{_id, document}} label="Content type">{document.content_type}</:col>
        <:col :let={{_id, document}} label="Storage path">{document.storage_path}</:col>
        <:col :let={{_id, document}} label="File size">{document.file_size}</:col>
        <:col :let={{_id, document}} label="Domain type">{document.domain_type}</:col>
        <:col :let={{_id, document}} label="Domain type source">{document.domain_type_source}</:col>
        <:col :let={{_id, document}} label="Status">{document.status}</:col>
        <:col :let={{_id, document}} label="Raw text">{document.raw_text}</:col>
        <:col :let={{_id, document}} label="Page count">{document.page_count}</:col>
        <:col :let={{_id, document}} label="Error message">{document.error_message}</:col>
        <:col :let={{_id, document}} label="Processing started at">
          {document.processing_started_at}
        </:col>
        <:col :let={{_id, document}} label="Processing completed at">
          {document.processing_completed_at}
        </:col>
        <:action :let={{_id, document}}>
          <div class="sr-only">
            <.link navigate={~p"/documents/#{document}"}>Show</.link>
          </div>
          <.link navigate={~p"/documents/#{document}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, document}}>
          <.link
            phx-click={JS.push("delete", value: %{id: document.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Documents")
     |> stream(:documents, Documents.list_documents())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Documents.get_document(id) do
      {:ok, document} ->
        {:ok, _} = Documents.delete_document(document)
        {:noreply, stream_delete(socket, :documents, document)}

      {:error, :not_found} ->
        {:noreply, socket}
    end
  end
end
