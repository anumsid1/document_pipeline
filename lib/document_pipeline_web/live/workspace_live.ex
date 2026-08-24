defmodule DocumentPipelineWeb.WorkspaceLive do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Projects
  alias DocumentPipeline.Documents

  @domain_types [
    {"Invoice", "invoice"},
    {"Budget", "budget"},
    {"Change order", "change_order"},
    {"Pay application", "pay_application"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Workspace")
      |> assign(:projects, Projects.list_projects())
      |> assign(:selected_project, nil)
      |> assign(:selected_document, nil)
      |> assign(:selected_document_id, nil)
      |> assign(:editing_field_id, nil)
      |> assign(:subscribed_document_ids, MapSet.new())
      |> assign(:domain_types, @domain_types)
      |> stream(:documents, [])
      |> allow_upload(:document,
        accept: ~w(.pdf .xlsx .xls),
        max_entries: 1,
        max_file_size: 20_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"project_id" => project_id}, _uri, socket) do
    {:noreply, select_project(socket, project_id)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-7xl">
        <.header>
          Workspace
          <:subtitle>Upload documents, watch extraction happen live, and correct results.</:subtitle>
        </.header>

        <div class="grid grid-cols-1 lg:grid-cols-[16rem_1fr_1fr] gap-6 items-start">
          <div class="space-y-2">
            <h2 class="font-semibold text-sm uppercase opacity-60">Projects</h2>
            <ul class="space-y-1">
              <li :for={project <- @projects}>
                <button
                  type="button"
                  phx-click="select_project"
                  phx-value-id={project.id}
                  class={[
                    "btn btn-sm btn-block justify-start",
                    (@selected_project && @selected_project.id == project.id && "btn-primary") ||
                      "btn-ghost"
                  ]}
                >
                  {project.name}
                </button>
              </li>
            </ul>
            <p :if={@projects == []} class="text-sm opacity-60">No projects yet.</p>
          </div>

          <div class="space-y-4">
            <div :if={@selected_project}>
              <h2 class="font-semibold text-sm uppercase opacity-60 mb-2">
                Documents — {@selected_project.name}
              </h2>

              <.form
                for={%{}}
                id="upload-form"
                phx-submit="upload"
                phx-change="validate_upload"
                class="flex items-center gap-2 mb-4"
              >
                <.live_file_input upload={@uploads.document} />
                <.button type="submit" variant="primary">Upload</.button>
              </.form>
              <p :for={entry <- @uploads.document.entries} class="text-sm opacity-70">
                {entry.client_name} — {entry.progress}%
              </p>
              <p :for={err <- upload_errors(@uploads.document)} class="text-sm text-error">
                {upload_error_to_string(err)}
              </p>

              <.table
                id="documents"
                rows={@streams.documents}
                row_click={fn {_id, doc} -> JS.push("select_document", value: %{id: doc.id}) end}
              >
                <:col :let={{_id, doc}} label="Filename">{doc.filename}</:col>
                <:col :let={{_id, doc}} label="Type">{doc.domain_type || "—"}</:col>
                <:col :let={{_id, doc}} label="Status"><.status_badge status={doc.status} /></:col>
              </.table>
            </div>

            <p :if={!@selected_project} class="text-sm opacity-60">
              Select a project to see its documents.
            </p>
          </div>

          <div>
            <div :if={@selected_document}>
              <h2 class="font-semibold text-sm uppercase opacity-60 mb-2">
                {@selected_document.filename}
              </h2>

              <div class="mb-4 flex items-center gap-3">
                <.status_badge status={@selected_document.status} />
                <.form for={%{}} id="type-correction-form" phx-change="correct_type">
                  <.input
                    type="select"
                    name="domain_type"
                    value={@selected_document.domain_type}
                    options={@domain_types}
                    prompt="Correct type…"
                  />
                </.form>
              </div>

              <h3 class="font-semibold text-sm mb-1">Extracted fields</h3>
              <ul class="mb-4">
                <li
                  :for={field <- Enum.sort_by(@selected_document.document_fields, & &1.field_name)}
                  id={"field-#{field.id}"}
                  class="flex items-center gap-2 py-1"
                >
                  <span class="w-40 shrink-0 text-sm opacity-70">{field.field_name}</span>

                  <.form
                    :if={@editing_field_id == field.id}
                    for={%{}}
                    id={"edit-field-#{field.id}"}
                    phx-submit="save_field"
                    class="flex items-center gap-2 flex-1"
                  >
                    <input type="hidden" name="field_id" value={field.id} />
                    <input
                      type="text"
                      name="value"
                      value={field.field_value}
                      class="input input-sm flex-1"
                    />
                    <button type="submit" class="btn btn-sm btn-primary">Save</button>
                    <button type="button" phx-click="cancel_edit_field" class="btn btn-sm btn-ghost">
                      Cancel
                    </button>
                  </.form>

                  <div :if={@editing_field_id != field.id} class="flex items-center gap-2 flex-1">
                    <span class="flex-1">{field.field_value}</span>
                    <span class="text-xs opacity-50">{field.source}</span>
                    <button
                      type="button"
                      phx-click="edit_field"
                      phx-value-id={field.id}
                      class="btn btn-xs btn-ghost"
                    >
                      Edit
                    </button>
                  </div>
                </li>
              </ul>
              <p :if={@selected_document.document_fields == []} class="text-sm opacity-60">
                No fields extracted yet.
              </p>

              <h3 class="font-semibold text-sm mb-1">Line items</h3>
              <.table
                :if={@selected_document.document_line_items != []}
                id="line-items"
                rows={Enum.sort_by(@selected_document.document_line_items, & &1.line_number)}
              >
                <:col :let={item} label="Description">{item.description}</:col>
                <:col :let={item} label="Amount">{item.amount}</:col>
                <:col :let={item} label="Category">{item.category}</:col>
              </.table>
              <p :if={@selected_document.document_line_items == []} class="text-sm opacity-60">
                No line items.
              </p>
            </div>

            <p :if={!@selected_document} class="text-sm opacity-60">
              Select a document to see its details.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("select_project", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/workspace/#{id}")}
  end

  def handle_event("select_document", %{"id" => id}, socket) do
    socket =
      case Documents.get_document(to_id(id)) do
        {:ok, document} ->
          socket
          |> assign(:selected_document, document)
          |> assign(:selected_document_id, document.id)
          |> assign(:editing_field_id, nil)

        {:error, :not_found} ->
          put_flash(socket, :error, "Document not found")
      end

    {:noreply, socket}
  end

  def handle_event("validate_upload", _params, socket), do: {:noreply, socket}

  def handle_event("upload", _params, socket) do
    project = socket.assigns.selected_project

    uploaded =
      consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
        {:ok, {entry, File.read!(path)}}
      end)

    socket =
      case uploaded do
        [{entry, binary}] ->
          case Documents.upload_document(project.id, entry.client_name, entry.client_type, binary) do
            {:ok, document} ->
              subscribe_document(document.id)

              socket
              |> stream_insert(:documents, document, at: 0)
              |> update(:subscribed_document_ids, &MapSet.put(&1, document.id))
              |> put_flash(:info, "#{document.filename} uploaded")

            {:error, _changeset} ->
              put_flash(socket, :error, "Upload failed")
          end

        [] ->
          put_flash(socket, :error, "Select a file first")
      end

    {:noreply, socket}
  end

  def handle_event("edit_field", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_field_id, to_id(id))}
  end

  def handle_event("cancel_edit_field", _params, socket) do
    {:noreply, assign(socket, :editing_field_id, nil)}
  end

  def handle_event("save_field", %{"field_id" => id, "value" => value}, socket) do
    socket =
      case Documents.update_field(to_id(id), value) do
        {:ok, _field} -> refresh_selected_document(socket)
        {:error, :not_found} -> put_flash(socket, :error, "Field not found")
      end
      |> assign(:editing_field_id, nil)

    {:noreply, socket}
  end

  def handle_event("correct_type", %{"domain_type" => new_type}, socket) do
    document_id = socket.assigns.selected_document.id

    socket =
      case Documents.correct_document_type(document_id, new_type) do
        {:ok, _document} ->
          socket
          |> refresh_selected_document()
          |> refresh_document_in_list(document_id)
          |> put_flash(:info, "Type corrected — reprocessing")

        {:error, :not_found} ->
          put_flash(socket, :error, "Document not found")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:document_processed, document_id}, socket) do
    socket =
      case Documents.get_document(document_id) do
        {:ok, document} ->
          socket
          |> stream_insert(:documents, document)
          |> maybe_update_selected_document(document)

        {:error, :not_found} ->
          socket
      end

    {:noreply, socket}
  end

  defp select_project(socket, project_id) do
    Enum.each(socket.assigns.subscribed_document_ids, &unsubscribe_document/1)

    case Projects.get_project(to_id(project_id)) do
      {:ok, project} ->
        documents = Documents.list_documents_for_projects(project.id)
        Enum.each(documents, &subscribe_document(&1.id))

        socket
        |> assign(:selected_project, project)
        |> assign(:selected_document, nil)
        |> assign(:selected_document_id, nil)
        |> assign(:editing_field_id, nil)
        |> assign(:subscribed_document_ids, MapSet.new(documents, & &1.id))
        |> stream(:documents, documents, reset: true)

      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Project not found")
        |> assign(:selected_project, nil)
        |> assign(:subscribed_document_ids, MapSet.new())
    end
  end

  defp refresh_selected_document(socket) do
    case socket.assigns.selected_document_id do
      nil ->
        socket

      id ->
        case Documents.get_document(id) do
          {:ok, document} -> assign(socket, :selected_document, document)
          {:error, :not_found} -> socket
        end
    end
  end

  defp refresh_document_in_list(socket, document_id) do
    case Documents.get_document(document_id) do
      {:ok, document} -> stream_insert(socket, :documents, document)
      {:error, :not_found} -> socket
    end
  end

  defp maybe_update_selected_document(socket, document) do
    if socket.assigns.selected_document_id == document.id do
      assign(socket, :selected_document, document)
    else
      socket
    end
  end

  defp subscribe_document(id),
    do: Phoenix.PubSub.subscribe(DocumentPipeline.PubSub, "document#{id}")

  defp unsubscribe_document(id),
    do: Phoenix.PubSub.unsubscribe(DocumentPipeline.PubSub, "document#{id}")

  defp to_id(id) when is_binary(id), do: String.to_integer(id)
  defp to_id(id) when is_integer(id), do: id

  defp upload_error_to_string(:too_large), do: "File is too large"
  defp upload_error_to_string(:too_many_files), do: "Only one file at a time"
  defp upload_error_to_string(:not_accepted), do: "Unsupported file type"
  defp upload_error_to_string(err), do: to_string(err)

  attr :status, :string, required: true

  defp status_badge(assigns) do
    {class, label} =
      case assigns.status do
        "uploaded" -> {"badge-neutral", "Uploaded"}
        "processing" -> {"badge-info", "Processing"}
        "processed" -> {"badge-success", "Processed"}
        "requires_review" -> {"badge-warning", "Needs review"}
        "failed" -> {"badge-error", "Failed"}
        other -> {"badge-ghost", other || "Unknown"}
      end

    assigns = assign(assigns, class: class, label: label)

    ~H"""
    <span class={["badge", @class]}>{@label}</span>
    """
  end
end
