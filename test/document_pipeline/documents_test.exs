defmodule DocumentPipeline.DocumentsTest do
  use DocumentPipeline.DataCase, async: true

  alias DocumentPipeline.Documents

  import DocumentPipeline.ProjectsFixtures

  setup do
    %{project: project_fixture()}
  end

  describe "upload_document/4" do
    test "creates document and enqueues job", %{project: project} do
      {:ok, doc} =
        Documents.upload_document(
          project.id,
          "invoice.pdf",
          "application/pdf",
          "fake pdf binary"
        )

      assert doc.filename == "invoice.pdf"
      assert doc.status == "uploaded"
      assert doc.project_id == project.id
    end
  end

  describe "update_field/2" do
    test "updates field value and sets source to user", %{project: project} do
      {:ok, doc} =
        Documents.upload_document(
          project.id,
          "test.pdf",
          "application/pdf",
          "binary"
        )

      Documents.save_extracted_fields(doc, %{
        "vendor_name" => "Wrong Name"
      })

      {:ok, updated_doc} = Documents.get_document(doc.id)
      field = hd(updated_doc.document_fields)

      {:ok, corrected} = Documents.update_field(field.id, "Correct Name")

      assert corrected.field_value == "Correct Name"
      assert corrected.source == "user"
      assert corrected.confidence == 1.0
    end
  end

  describe "get_documents_by_type/2" do
    test "filters by domain type", %{project: project} do
      {:ok, doc1} =
        Documents.upload_document(
          project.id,
          "inv.pdf",
          "application/pdf",
          "bin"
        )

      {:ok, doc2} =
        Documents.upload_document(
          project.id,
          "budget.xlsx",
          "application/pdf",
          "bin"
        )

      Documents.update_document_type(doc1, "invoice")
      Documents.update_document_type(doc2, "budget")

      invoices = Documents.get_documents_by_type(project.id, "invoice")
      assert length(invoices) == 1
      assert hd(invoices).domain_type == "invoice"
    end
  end
end
