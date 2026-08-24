defmodule DocumentPipelineWeb.DocumentLineItemLive.Show do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Document line item {@document_line_item.id}
        <:subtitle>This is a document_line_item record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/document_line_items"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/document_line_items/#{@document_line_item}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit document_line_item
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Description">{@document_line_item.description}</:item>
        <:item title="Amount">{@document_line_item.amount}</:item>
        <:item title="Category">{@document_line_item.category}</:item>
        <:item title="Line number">{@document_line_item.line_number}</:item>
        <:item title="Source">{@document_line_item.source}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Document line item")
     |> assign(:document_line_item, Documents.get_document_line_item!(id))}
  end
end
