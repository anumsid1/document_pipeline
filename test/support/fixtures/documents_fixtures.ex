defmodule DocumentPipeline.DocumentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DocumentPipeline.Documents` context.
  """

  @doc """
  Generate a document.
  """
  def document_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    project_id = attrs[:project_id] || DocumentPipeline.ProjectsFixtures.project_fixture().id

    {:ok, document} =
      attrs
      |> Enum.into(%{
        project_id: project_id,
        content_type: "some content_type",
        domain_type: "some domain_type",
        domain_type_source: "some domain_type_source",
        error_message: "some error_message",
        file_size: 42,
        filename: "some filename",
        page_count: 42,
        processing_completed_at: ~U[2026-08-22 01:58:00Z],
        processing_started_at: ~U[2026-08-22 01:58:00Z],
        raw_text: "some raw_text",
        status: "some status",
        storage_path: "some storage_path"
      })
      |> DocumentPipeline.Documents.create_document()

    document
  end

  @doc """
  Generate a document_field.
  """
  def document_field_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    document_id = attrs[:document_id] || document_fixture().id

    {:ok, document_field} =
      attrs
      |> Enum.into(%{
        document_id: document_id,
        confidence: 120.5,
        field_name: "some field_name",
        field_value: "some field_value",
        source: "system"
      })
      |> DocumentPipeline.Documents.create_document_field()

    document_field
  end

  @doc """
  Generate a document_line_item.
  """
  def document_line_item_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    document_id = attrs[:document_id] || document_fixture().id

    {:ok, document_line_item} =
      attrs
      |> Enum.into(%{
        document_id: document_id,
        amount: "120.5",
        category: "some category",
        description: "some description",
        line_number: 42,
        source: "system"
      })
      |> DocumentPipeline.Documents.create_document_line_item()

    document_line_item
  end
end
