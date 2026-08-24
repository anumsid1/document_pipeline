defmodule DocumentPipelineWeb.WorkspaceLiveTest do
  use DocumentPipelineWeb.ConnCase
  use Oban.Testing, repo: DocumentPipeline.Repo

  import Phoenix.LiveViewTest
  import DocumentPipeline.ProjectsFixtures
  import DocumentPipeline.DocumentsFixtures

  alias DocumentPipeline.Documents
  alias DocumentPipeline.Workers.ProcessDocumentWorker

  describe "project selection" do
    test "lists projects", %{conn: conn} do
      project = project_fixture()

      {:ok, _view, html} = live(conn, ~p"/workspace")

      assert html =~ project.name
    end

    test "selecting a project shows only its documents", %{conn: conn} do
      project_a = project_fixture()
      project_b = project_fixture()
      doc_a = document_fixture(project_id: project_a.id, filename: "a.pdf")
      doc_b = document_fixture(project_id: project_b.id, filename: "b.pdf")

      {:ok, view, _html} = live(conn, ~p"/workspace")

      html =
        view
        |> element("button[phx-click=select_project][phx-value-id='#{project_a.id}']")
        |> render_click()

      assert html =~ doc_a.filename
      refute html =~ doc_b.filename
    end
  end

  describe "upload" do
    test "uploading a document adds it to the list", %{conn: conn} do
      project = project_fixture()

      {:ok, view, _html} = live(conn, ~p"/workspace/#{project.id}")

      file =
        file_input(view, "#upload-form", :document, [
          %{
            name: "invoice.pdf",
            content: "fake pdf binary",
            type: "application/pdf"
          }
        ])

      assert render_upload(file, "invoice.pdf") =~ "100%"

      html =
        view
        |> form("#upload-form")
        |> render_submit()

      assert html =~ "invoice.pdf"
      assert html =~ "Uploaded"
    end
  end

  describe "field inline edit" do
    test "editing a field updates its value and marks it user-corrected", %{conn: conn} do
      document = document_fixture()
      field = document_field_fixture(document_id: document.id)

      {:ok, view, _html} = live(conn, ~p"/workspace/#{document.project_id}")

      view
      |> element("#documents-#{document.id} td:first-child")
      |> render_click()

      assert has_element?(view, "#field-#{field.id}")

      view
      |> element("button[phx-click=edit_field][phx-value-id='#{field.id}']")
      |> render_click()

      html =
        view
        |> form("#edit-field-#{field.id}", %{"value" => "Corrected Value"})
        |> render_submit()

      assert html =~ "Corrected Value"

      {:ok, updated} = Documents.get_document(document.id)
      updated_field = Enum.find(updated.document_fields, &(&1.id == field.id))
      assert updated_field.field_value == "Corrected Value"
      assert updated_field.source == "user"
      assert updated_field.confidence == 1.0
    end
  end

  describe "type correction" do
    test "correcting the type wipes extracted data and re-enqueues processing", %{conn: conn} do
      document = document_fixture(domain_type: "invoice")
      document_field_fixture(document_id: document.id)

      {:ok, view, _html} = live(conn, ~p"/workspace/#{document.project_id}")

      view
      |> element("#documents-#{document.id} td:first-child")
      |> render_click()

      view
      |> form("#type-correction-form", %{"domain_type" => "budget"})
      |> render_change()

      {:ok, updated} = Documents.get_document(document.id)
      assert updated.domain_type == "budget"
      assert updated.domain_type_source == "user"
      assert updated.document_fields == []

      assert_enqueued(worker: ProcessDocumentWorker, args: %{document_id: document.id})
    end
  end

  describe "pubsub live update" do
    test "a broadcast for the selected document refreshes the detail pane", %{conn: conn} do
      document = document_fixture(status: "uploaded")

      {:ok, view, _html} = live(conn, ~p"/workspace/#{document.project_id}")

      view
      |> element("#documents-#{document.id} td:first-child")
      |> render_click()

      assert has_element?(view, "span", "Uploaded")

      {:ok, _} = Documents.update_document_status(document, "processed")

      Phoenix.PubSub.broadcast(
        DocumentPipeline.PubSub,
        "document#{document.id}",
        {:document_processed, document.id}
      )

      assert render(view) =~ "Processed"
    end

    test "a broadcast for a failed document shows the failed badge", %{conn: conn} do
      document = document_fixture()

      {:ok, view, _html} = live(conn, ~p"/workspace/#{document.project_id}")

      view
      |> element("#documents-#{document.id} td:first-child")
      |> render_click()

      {:ok, _} = Documents.update_document_status(document, "failed", "boom")

      Phoenix.PubSub.broadcast(
        DocumentPipeline.PubSub,
        "document#{document.id}",
        {:document_processed, document.id}
      )

      assert render(view) =~ "Failed"
    end
  end
end
