defmodule DocumentPipeline.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :address, :string
    field :total_budget, :decimal
    field :status, :string

    has_many :documents, DocumentPipeline.Documents.Document
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :address, :total_budget, :status])
    |> validate_required([:name, :address, :total_budget, :status])
  end
end
