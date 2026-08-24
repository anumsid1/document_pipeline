defmodule DocumentPipeline.Documents.DocumentLineItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "document_line_items" do
    field :description, :string
    field :amount, :decimal
    field :category, :string
    field :line_number, :integer
    field :source, :string

    belongs_to :document, DocumentPipeline.Documents.Document

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document_line_item, attrs) do
    document_line_item
    |> cast(attrs, [:description, :amount, :category, :line_number, :source, :document_id])
    |> validate_required([:description, :amount, :category, :line_number, :source, :document_id])
  end
end
