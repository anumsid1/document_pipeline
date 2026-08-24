defmodule DocumentPipeline.Documents.Document do
  use Ecto.Schema
  import Ecto.Changeset

  schema "documents" do
    field :filename, :string
    field :content_type, :string
    field :storage_path, :string
    field :file_size, :integer
    field :domain_type, :string
    field :domain_type_source, :string
    field :status, :string
    field :raw_text, :string
    field :page_count, :integer
    field :error_message, :string
    field :processing_started_at, :utc_datetime
    field :processing_completed_at, :utc_datetime

    belongs_to :project, DocumentPipeline.Projects.Project
    has_many :document_fields, DocumentPipeline.Documents.DocumentField
    has_many :document_line_items, DocumentPipeline.Documents.DocumentLineItem
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :filename,
      :content_type,
      :storage_path,
      :file_size,
      :domain_type,
      :domain_type_source,
      :status,
      :raw_text,
      :page_count,
      :error_message,
      :processing_started_at,
      :processing_completed_at,
      :project_id
    ])
    |> validate_required([
      :filename,
      :content_type,
      :storage_path,
      :file_size,
      :status,
      :project_id
    ])
  end
end
