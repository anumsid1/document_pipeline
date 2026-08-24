defmodule DocumentPipelineWeb.DocumentLineItemLive.Index do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Document line items
        <:actions>
          <.button variant="primary" navigate={~p"/document_line_items/new"}>
            <.icon name="hero-plus" /> New Document line item
          </.button>
        </:actions>
      </.header>

      <.table
        id="document_line_items"
        rows={@streams.document_line_items}
        row_click={
          fn {_id, document_line_item} ->
            JS.navigate(~p"/document_line_items/#{document_line_item}")
          end
        }
      >
        <:col :let={{_id, document_line_item}} label="Description">
          {document_line_item.description}
        </:col>
        <:col :let={{_id, document_line_item}} label="Amount">{document_line_item.amount}</:col>
        <:col :let={{_id, document_line_item}} label="Category">{document_line_item.category}</:col>
        <:col :let={{_id, document_line_item}} label="Line number">
          {document_line_item.line_number}
        </:col>
        <:col :let={{_id, document_line_item}} label="Source">{document_line_item.source}</:col>
        <:action :let={{_id, document_line_item}}>
          <div class="sr-only">
            <.link navigate={~p"/document_line_items/#{document_line_item}"}>Show</.link>
          </div>
          <.link navigate={~p"/document_line_items/#{document_line_item}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, document_line_item}}>
          <.link
            phx-click={JS.push("delete", value: %{id: document_line_item.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Document line items")
     |> stream(:document_line_items, list_document_line_items())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    document_line_item = Documents.get_document_line_item!(id)
    {:ok, _} = Documents.delete_document_line_item(document_line_item)

    {:noreply, stream_delete(socket, :document_line_items, document_line_item)}
  end

  defp list_document_line_items() do
    Documents.list_document_line_items()
  end
end
