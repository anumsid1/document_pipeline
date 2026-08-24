defmodule DocumentPipeline.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :filename, :string
      add :content_type, :string
      add :storage_path, :string
      add :file_size, :integer
      add :domain_type, :string
      add :domain_type_source, :string
      add :status, :string
      add :raw_text, :text
      add :page_count, :integer
      add :error_message, :string
      add :processing_started_at, :utc_datetime
      add :processing_completed_at, :utc_datetime
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:documents, [:project_id])
  end
end
