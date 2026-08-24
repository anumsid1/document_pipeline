defmodule DocumentPipeline.Repo.Migrations.CreateDocumentFields do
  use Ecto.Migration

  def change do
    create table(:document_fields) do
      add :field_name, :string
      add :field_value, :string
      add :confidence, :float
      add :source, :string
      add :document_id, references(:documents, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:document_fields, [:document_id])
  end
end
