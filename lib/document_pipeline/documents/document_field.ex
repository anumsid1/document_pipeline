defmodule DocumentPipeline.Documents.DocumentField do
  use Ecto.Schema
  import Ecto.Changeset

  schema "document_fields" do
    field :field_name, :string
    field :field_value, :string
    field :confidence, :float
    field :source, :string

    belongs_to :document, DocumentPipeline.Documents.Document

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document_field, attrs) do
    document_field
    |> cast(attrs, [:field_name, :field_value, :confidence, :source, :document_id])
    |> validate_required([:field_name, :field_value, :confidence, :source, :document_id])
    |> validate_inclusion(:source, ~w(system user))
  end
end
