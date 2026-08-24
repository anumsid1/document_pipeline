defmodule DocumentPipeline.Documents do
  @moduledoc """
  The Documents context.
  """

  import Ecto.Query, warn: false
  alias DocumentPipeline.Repo

  alias DocumentPipeline.Documents.Document
  alias DocumentPipeline.Documents.DocumentField
  alias DocumentPipeline.Documents.DocumentLineItem

  # ── Documents ──────────────────────────────────────

  @doc """
  Returns the list of all documents, newest first, with their fields and
  line items preloaded.

  ## Examples

      iex> list_documents()
      [%Document{}, ...]

  """
  def list_documents do
    Document
    |> preload([:document_fields, :document_line_items])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of documents for a project, newest first, with their
  fields and line items preloaded.

  ## Examples

      iex> list_documents_for_projects(project_id)
      [%Document{}, ...]

  """
  def list_documents_for_projects(project_id) do
    Document
    |> where([d], d.project_id == ^project_id)
    |> preload([:document_fields, :document_line_items])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single document, with its fields and line items preloaded.

  Returns `{:error, :not_found}` if the Document does not exist.

  ## Examples

      iex> get_document(123)
      {:ok, %Document{}}

      iex> get_document(456)
      {:error, :not_found}

  """
  def get_document(id) do
    Document
    |> preload([:document_fields, :document_line_items])
    |> Repo.get(id)
    |> case do
      nil -> {:error, :not_found}
      document -> {:ok, document}
    end
  end

  @doc """
  Returns the list of documents for a project matching the given domain type.

  ## Examples

      iex> get_documents_by_type(project_id, "invoice")
      [%Document{}, ...]

  """
  def get_documents_by_type(project_id, domain_type) do
    Document
    |> where([d], d.project_id == ^project_id)
    |> where([d], d.domain_type == ^domain_type)
    |> preload([:document_fields, :document_line_items])
    |> Repo.all()
  end

  @doc """
  Returns the list of documents for a project that require review, newest
  first (status `"requires_review"` or `"failed"`).

  ## Examples

      iex> get_documents_needing_review(project_id)
      [%Document{}, ...]

  """
  def get_documents_needing_review(project_id) do
    Document
    |> where([d], d.project_id == ^project_id)
    |> where([d], d.status in ["requires_review", "failed"])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Creates a document.

  ## Examples

      iex> create_document(%{field: value})
      {:ok, %Document{}}

      iex> create_document(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_document(attrs) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Stores an uploaded file, creates its document record, and enqueues it for
  processing.

  ## Examples

      iex> upload_document(project_id, "invoice.pdf", "application/pdf", binary)
      {:ok, %Document{}}

  """
  def upload_document(project_id, filename, content_type, file_binary) do
    storage_path = store_file(filename, file_binary)

    attrs = %{
      project_id: project_id,
      filename: filename,
      content_type: content_type,
      storage_path: storage_path,
      file_size: byte_size(file_binary),
      status: "uploaded"
    }

    with {:ok, document} <- create_document(attrs) do
      %{document_id: document.id}
      |> DocumentPipeline.Workers.ProcessDocumentWorker.new()
      |> Oban.insert()

      {:ok, document}
    end
  end

  @doc """
  Updates a document.

  ## Examples

      iex> update_document(document, %{field: new_value})
      {:ok, %Document{}}

      iex> update_document(document, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a document's processing status and, optionally, its error message.
  Stamps `processing_started_at`/`processing_completed_at` when the status
  is `"processing"`/`"processed"`.

  ## Examples

      iex> update_document_status(document, "processed")
      {:ok, %Document{}}

  """
  def update_document_status(document, status, error \\ nil) do
    attrs = %{status: status, error_message: error}

    attrs =
      if status == "processing" do
        Map.put(attrs, :processing_started_at, DateTime.utc_now())
      else
        attrs
      end

    attrs =
      if status == "processed" do
        Map.put(attrs, :processing_completed_at, DateTime.utc_now())
      else
        attrs
      end

    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a document's domain type and records the source of that
  classification (defaults to `"system"`).

  ## Examples

      iex> update_document_type(document, "invoice")
      {:ok, %Document{}}

  """
  def update_document_type(document, domain_type, source \\ "system") do
    document
    |> Document.changeset(%{
      domain_type: domain_type,
      domain_type_source: source
    })
    |> Repo.update()
  end

  @doc """
  Stores the raw extracted text for a document.

  ## Examples

      iex> save_raw_text(document, "...text...")
      {:ok, %Document{}}

  """
  def save_raw_text(document, text) do
    document
    |> Document.changeset(%{raw_text: text})
    |> Repo.update()
  end

  @doc """
  Corrects a document's type after the fact: wipes its previously extracted
  fields and line items, updates the type, and re-enqueues extraction.

  ## Examples

      iex> correct_document_type(document_id, "receipt")
      {:ok, %Document{}}

      iex> correct_document_type(bad_id, "receipt")
      {:error, :not_found}

  """
  def correct_document_type(document_id, new_type) do
    with {:ok, document} <- get_document(document_id) do
      Repo.delete_all(
        from f in DocumentField,
          where: f.document_id == ^document_id
      )

      Repo.delete_all(
        from li in DocumentLineItem,
          where: li.document_id == ^document_id
      )

      {:ok, updated} = update_document_type(document, new_type, "user")

      %{document_id: document.id, skip_classification: true}
      |> DocumentPipeline.Workers.ProcessDocumentWorker.new(unique: false)
      |> Oban.insert()

      {:ok, updated}
    end
  end

  @doc """
  Deletes a document.

  ## Examples

      iex> delete_document(document)
      {:ok, %Document{}}

      iex> delete_document(document)
      {:error, %Ecto.Changeset{}}

  """
  def delete_document(%Document{} = document) do
    Repo.delete(document)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking document changes.

  ## Examples

      iex> change_document(document)
      %Ecto.Changeset{data: %Document{}}

  """
  def change_document(%Document{} = document, attrs \\ %{}) do
    Document.changeset(document, attrs)
  end

  # ── Document fields ────────────────────────────────

  @doc """
  Returns the list of document_fields.

  ## Examples

      iex> list_document_fields()
      [%DocumentField{}, ...]

  """
  def list_document_fields do
    Repo.all(DocumentField)
  end

  @doc """
  Gets a single document_field.

  Raises `Ecto.NoResultsError` if the Document field does not exist.

  ## Examples

      iex> get_document_field!(123)
      %DocumentField{}

      iex> get_document_field!(456)
      ** (Ecto.NoResultsError)

  """
  def get_document_field!(id), do: Repo.get!(DocumentField, id)

  @doc """
  Creates a document_field.

  ## Examples

      iex> create_document_field(%{field: value})
      {:ok, %DocumentField{}}

      iex> create_document_field(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_document_field(attrs) do
    %DocumentField{}
    |> DocumentField.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a document_field.

  ## Examples

      iex> update_document_field(document_field, %{field: new_value})
      {:ok, %DocumentField{}}

      iex> update_document_field(document_field, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_document_field(%DocumentField{} = document_field, attrs) do
    document_field
    |> DocumentField.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Sets a document field's value as a user correction: marks its source as
  `"user"` and its confidence as `1.0`.

  Returns `{:error, :not_found}` if the field does not exist.

  ## Examples

      iex> update_field(field_id, "corrected value")
      {:ok, %DocumentField{}}

      iex> update_field(bad_id, "corrected value")
      {:error, :not_found}

  """
  def update_field(field_id, new_value) do
    case Repo.get(DocumentField, field_id) do
      nil ->
        {:error, :not_found}

      field ->
        field
        |> DocumentField.changeset(%{field_value: new_value, source: "user", confidence: 1.0})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a document_field.

  ## Examples

      iex> delete_document_field(document_field)
      {:ok, %DocumentField{}}

      iex> delete_document_field(document_field)
      {:error, %Ecto.Changeset{}}

  """
  def delete_document_field(%DocumentField{} = document_field) do
    Repo.delete(document_field)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking document_field changes.

  ## Examples

      iex> change_document_field(document_field)
      %Ecto.Changeset{data: %DocumentField{}}

  """
  def change_document_field(%DocumentField{} = document_field, attrs \\ %{}) do
    DocumentField.changeset(document_field, attrs)
  end

  # ── Document line items ────────────────────────────

  @doc """
  Returns the list of document_line_items.

  ## Examples

      iex> list_document_line_items()
      [%DocumentLineItem{}, ...]

  """
  def list_document_line_items do
    Repo.all(DocumentLineItem)
  end

  @doc """
  Gets a single document_line_item.

  Raises `Ecto.NoResultsError` if the Document line item does not exist.

  ## Examples

      iex> get_document_line_item!(123)
      %DocumentLineItem{}

      iex> get_document_line_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_document_line_item!(id), do: Repo.get!(DocumentLineItem, id)

  @doc """
  Creates a document_line_item.

  ## Examples

      iex> create_document_line_item(%{field: value})
      {:ok, %DocumentLineItem{}}

      iex> create_document_line_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_document_line_item(attrs) do
    %DocumentLineItem{}
    |> DocumentLineItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a document_line_item.

  ## Examples

      iex> update_document_line_item(document_line_item, %{field: new_value})
      {:ok, %DocumentLineItem{}}

      iex> update_document_line_item(document_line_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_document_line_item(%DocumentLineItem{} = document_line_item, attrs) do
    document_line_item
    |> DocumentLineItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a document_line_item.

  ## Examples

      iex> delete_document_line_item(document_line_item)
      {:ok, %DocumentLineItem{}}

      iex> delete_document_line_item(document_line_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_document_line_item(%DocumentLineItem{} = document_line_item) do
    Repo.delete(document_line_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking document_line_item changes.

  ## Examples

      iex> change_document_line_item(document_line_item)
      %Ecto.Changeset{data: %DocumentLineItem{}}

  """
  def change_document_line_item(%DocumentLineItem{} = document_line_item, attrs \\ %{}) do
    DocumentLineItem.changeset(document_line_item, attrs)
  end

  # ── Extraction results ─────────────────────────────

  @doc """
  Persists a map of extracted `{field_name, field_value}` pairs as
  system-sourced document_fields for a document.

  ## Examples

      iex> save_extracted_fields(document, %{"total" => "42.00"})
      {:ok, %Document{}}

  """
  def save_extracted_fields(document, field_maps) do
    Enum.each(field_maps, fn {name, value} ->
      %DocumentField{}
      |> DocumentField.changeset(%{
        document_id: document.id,
        field_name: to_string(name),
        field_value: to_string(value),
        confidence: 0.85,
        source: "system"
      })
      |> Repo.insert()
    end)

    {:ok, document}
  end

  @doc """
  Persists a list of extracted line item maps as system-sourced
  document_line_items for a document, numbered in order starting at 1.

  ## Examples

      iex> save_line_items(document, [%{"description" => "Widget", "amount" => "10.00"}])
      {:ok, %Document{}}

  """
  def save_line_items(document, items) do
    items
    |> Enum.with_index(1)
    |> Enum.each(fn {item, index} ->
      %DocumentLineItem{}
      |> DocumentLineItem.changeset(%{
        document_id: document.id,
        description: item["description"],
        amount: item["amount"],
        category: item["category"],
        line_number: index,
        source: "system"
      })
      |> Repo.insert!()
    end)

    {:ok, document}
  end

  # ── Private helpers ─────────────────────────────────

  defp store_file(filename, binary) do
    dir = Path.join(["priv", "uploads"])
    File.mkdir_p!(dir)
    path = Path.join(dir, "#{Ecto.UUID.generate()}_#{filename}")
    File.write!(path, binary)
    path
  end
end
