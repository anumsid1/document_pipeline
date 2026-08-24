defmodule DocumentPipelineWeb.DocumentFieldLive.Form do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents
  alias DocumentPipeline.Documents.DocumentField

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage document_field records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="document_field-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:document_id]}
          type="select"
          label="Document"
          options={Enum.map(@documents, &{&1.filename, &1.id})}
          prompt="Select a document"
        />
        <.input field={@form[:field_name]} type="text" label="Field name" />
        <.input field={@form[:field_value]} type="text" label="Field value" />
        <.input field={@form[:confidence]} type="number" label="Confidence" step="any" />
        <.input field={@form[:source]} type="text" label="Source" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Document field</.button>
          <.button navigate={return_path(@return_to, @document_field)}>Cancel</.button>
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
    document_field = Documents.get_document_field!(id)

    socket
    |> assign(:page_title, "Edit Document field")
    |> assign(:document_field, document_field)
    |> assign(:form, to_form(Documents.change_document_field(document_field)))
  end

  defp apply_action(socket, :new, _params) do
    document_field = %DocumentField{}

    socket
    |> assign(:page_title, "New Document field")
    |> assign(:document_field, document_field)
    |> assign(:form, to_form(Documents.change_document_field(document_field)))
  end

  @impl true
  def handle_event("validate", %{"document_field" => document_field_params}, socket) do
    changeset =
      Documents.change_document_field(socket.assigns.document_field, document_field_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"document_field" => document_field_params}, socket) do
    save_document_field(socket, socket.assigns.live_action, document_field_params)
  end

  defp save_document_field(socket, :edit, document_field_params) do
    case Documents.update_document_field(socket.assigns.document_field, document_field_params) do
      {:ok, document_field} ->
        {:noreply,
         socket
         |> put_flash(:info, "Document field updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, document_field))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_document_field(socket, :new, document_field_params) do
    case Documents.create_document_field(document_field_params) do
      {:ok, document_field} ->
        {:noreply,
         socket
         |> put_flash(:info, "Document field created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, document_field))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _document_field), do: ~p"/document_fields"
  defp return_path("show", document_field), do: ~p"/document_fields/#{document_field}"
end
