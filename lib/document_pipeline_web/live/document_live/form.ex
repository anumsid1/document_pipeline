defmodule DocumentPipelineWeb.DocumentLive.Form do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Documents
  alias DocumentPipeline.Documents.Document
  alias DocumentPipeline.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage document records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="document-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:project_id]}
          type="select"
          label="Project"
          options={Enum.map(@projects, &{&1.name, &1.id})}
          prompt="Select a project"
        />
        <.input field={@form[:filename]} type="text" label="Filename" />
        <.input field={@form[:content_type]} type="text" label="Content type" />
        <.input field={@form[:storage_path]} type="text" label="Storage path" />
        <.input field={@form[:file_size]} type="number" label="File size" />
        <.input field={@form[:domain_type]} type="text" label="Domain type" />
        <.input field={@form[:domain_type_source]} type="text" label="Domain type source" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:raw_text]} type="textarea" label="Raw text" />
        <.input field={@form[:page_count]} type="number" label="Page count" />
        <.input field={@form[:error_message]} type="text" label="Error message" />
        <.input
          field={@form[:processing_started_at]}
          type="datetime-local"
          label="Processing started at"
        />
        <.input
          field={@form[:processing_completed_at]}
          type="datetime-local"
          label="Processing completed at"
        />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Document</.button>
          <.button navigate={return_path(@return_to, @document)}>Cancel</.button>
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
     |> assign(:projects, Projects.list_projects())
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Documents.get_document(id) do
      {:ok, document} ->
        socket
        |> assign(:page_title, "Edit Document")
        |> assign(:document, document)
        |> assign(:form, to_form(Documents.change_document(document)))

      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Document not found")
        |> push_navigate(to: ~p"/documents")
    end
  end

  defp apply_action(socket, :new, _params) do
    document = %Document{}

    socket
    |> assign(:page_title, "New Document")
    |> assign(:document, document)
    |> assign(:form, to_form(Documents.change_document(document)))
  end

  @impl true
  def handle_event("validate", %{"document" => document_params}, socket) do
    changeset = Documents.change_document(socket.assigns.document, document_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"document" => document_params}, socket) do
    save_document(socket, socket.assigns.live_action, document_params)
  end

  defp save_document(socket, :edit, document_params) do
    case Documents.update_document(socket.assigns.document, document_params) do
      {:ok, document} ->
        {:noreply,
         socket
         |> put_flash(:info, "Document updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, document))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_document(socket, :new, document_params) do
    case Documents.create_document(document_params) do
      {:ok, document} ->
        {:noreply,
         socket
         |> put_flash(:info, "Document created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, document))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _document), do: ~p"/documents"
  defp return_path("show", document), do: ~p"/documents/#{document}"
end
