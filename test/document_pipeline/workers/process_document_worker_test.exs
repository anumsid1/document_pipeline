defmodule DocumentPipeline.Workers.ProcessDocumentWorkerTest do
  use DocumentPipeline.DataCase, async: true
  use Oban.Testing, repo: DocumentPipeline.Repo

  alias DocumentPipeline.Workers.ProcessDocumentWorker
  alias DocumentPipeline.Documents

  import DocumentPipeline.ProjectsFixtures

  setup do
    project = project_fixture()

    {:ok, doc} =
      Documents.upload_document(
        project.id,
        "test_invoice.pdf",
        "application/pdf",
        "This is a test invoice from ABC Corp for $5000"
      )

    %{document: doc, project: project}
  end

  test "job is enqueued on upload", %{document: doc} do
    assert_enqueued(
      worker: ProcessDocumentWorker,
      args: %{document_id: doc.id},
      queue: :document_processing
    )
  end

  test "processes document and extracts data", %{document: doc} do
    assert :ok = perform_job(ProcessDocumentWorker, %{document_id: doc.id})

    {:ok, processed} = Documents.get_document(doc.id)
    assert processed.status == "processed"
    assert processed.domain_type != nil
    assert length(processed.document_fields) > 0
  end
end
