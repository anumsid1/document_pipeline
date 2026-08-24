defmodule DocumentPipelineWeb.DocumentFieldLive.Index do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Document fields
        <:actions>
          <.button variant="primary" navigate={~p"/document_fields/new"}>
            <.icon name="hero-plus" /> New Document field
          </.button>
        </:actions>
      </.header>

      <.table
        id="document_fields"
        rows={@streams.document_fields}
        row_click={
          fn {_id, document_field} -> JS.navigate(~p"/document_fields/#{document_field}") end
        }
      >
        <:col :let={{_id, document_field}} label="Field name">{document_field.field_name}</:col>
        <:col :let={{_id, document_field}} label="Field value">{document_field.field_value}</:col>
        <:col :let={{_id, document_field}} label="Confidence">{document_field.confidence}</:col>
        <:col :let={{_id, document_field}} label="Source">{document_field.source}</:col>
        <:action :let={{_id, document_field}}>
          <div class="sr-only">
            <.link navigate={~p"/document_fields/#{document_field}"}>Show</.link>
          </div>
          <.link navigate={~p"/document_fields/#{document_field}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, document_field}}>
          <.link
            phx-click={JS.push("delete", value: %{id: document_field.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Document fields")
     |> stream(:document_fields, list_document_fields())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    document_field = Documents.get_document_field!(id)
    {:ok, _} = Documents.delete_document_field(document_field)

    {:noreply, stream_delete(socket, :document_fields, document_field)}
  end

  defp list_document_fields() do
    Documents.list_document_fields()
  end
end
