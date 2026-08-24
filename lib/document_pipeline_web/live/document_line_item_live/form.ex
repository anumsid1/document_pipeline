defmodule DocumentPipelineWeb.DocumentLineItemLive.Form do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents
  alias DocumentPipeline.Documents.DocumentLineItem

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage document_line_item records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="document_line_item-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:document_id]}
          type="select"
          label="Document"
          options={Enum.map(@documents, &{&1.filename, &1.id})}
          prompt="Select a document"
        />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:amount]} type="number" label="Amount" step="any" />
        <.input field={@form[:category]} type="text" label="Category" />
        <.input field={@form[:line_number]} type="number" label="Line number" />
        <.input field={@form[:source]} type="text" label="Source" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Document line item</.button>
          <.button navigate={return_path(@return_to, @document_line_item)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:documents, Documents.list_documents())
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    document_line_item = Documents.get_document_line_item!(id)

    socket
    |> assign(:page_title, "Edit Document line item")
    |> assign(:document_line_item, document_line_item)
    |> assign(:form, to_form(Documents.change_document_line_item(document_line_item)))
  end

  defp apply_action(socket, :new, _params) do
    document_line_item = %DocumentLineItem{}

    socket
    |> assign(:page_title, "New Document line item")
    |> assign(:document_line_item, document_line_item)
    |> assign(:form, to_form(Documents.change_document_line_item(document_line_item)))
  end

  @impl true
  def handle_event("validate", %{"document_line_item" => document_line_item_params}, socket) do
    changeset =
      Documents.change_document_line_item(
        socket.assigns.document_line_item,
        document_line_item_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"document_line_item" => document_line_item_params}, socket) do
    save_document_line_item(socket, socket.assigns.live_action, document_line_item_params)
  end

  defp save_document_line_item(socket, :edit, document_line_item_params) do
    case Documents.update_document_line_item(
           socket.assigns.document_line_item,
           document_line_item_params
         ) do
      {:ok, document_line_item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Document line item updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, document_line_item))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_document_line_item(socket, :new, document_line_item_params) do
    case Documents.create_document_line_item(document_line_item_params) do
      {:ok, document_line_item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Document line item created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, document_line_item))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _document_line_item), do: ~p"/document_line_items"
  defp return_path("show", document_line_item), do: ~p"/document_line_items/#{document_line_item}"
end
