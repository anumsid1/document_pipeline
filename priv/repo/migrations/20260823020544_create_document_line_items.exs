defmodule DocumentPipeline.Repo.Migrations.CreateDocumentLineItems do
  use Ecto.Migration

  def change do
    create table(:document_line_items) do
      add :description, :string
      add :amount, :decimal
      add :category, :string
      add :line_number, :integer
      add :source, :string
      add :document_id, references(:documents, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:document_line_items, [:document_id])
  end
end
