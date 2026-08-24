defmodule DocumentPipeline.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      add :address, :string
      add :total_budget, :decimal
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
