defmodule DocumentPipelineWeb.DocumentLiveTest do
  use DocumentPipelineWeb.ConnCase

  import Phoenix.LiveViewTest
  import DocumentPipeline.DocumentsFixtures

  @create_attrs %{
    status: "some status",
    filename: "some filename",
    domain_type: "some domain_type",
    content_type: "some content_type",
    storage_path: "some storage_path",
    file_size: 42,
    domain_type_source: "some domain_type_source",
    raw_text: "some raw_text",
    page_count: 42,
    error_message: "some error_message",
    processing_started_at: "2026-08-22T01:58:00Z",
    processing_completed_at: "2026-08-22T01:58:00Z"
  }
  @update_attrs %{
    status: "some updated status",
    filename: "some updated filename",
    domain_type: "some updated domain_type",
    content_type: "some updated content_type",
    storage_path: "some updated storage_path",
    file_size: 43,
    domain_type_source: "some updated domain_type_source",
    raw_text: "some updated raw_text",
    page_count: 43,
    error_message: "some updated error_message",
    processing_started_at: "2026-08-23T01:58:00Z",
    processing_completed_at: "2026-08-23T01:58:00Z"
  }
  @invalid_attrs %{
    status: nil,
    filename: nil,
    domain_type: nil,
    content_type: nil,
    storage_path: nil,
    file_size: nil,
    domain_type_source: nil,
    raw_text: nil,
    page_count: nil,
    error_message: nil,
    processing_started_at: nil,
    processing_completed_at: nil
  }
  defp create_document(_) do
    document = document_fixture()

    %{document: document}
  end

  describe "Index" do
    setup [:create_document]

    test "lists all documents", %{conn: conn, document: document} do
      {:ok, _index_live, html} = live(conn, ~p"/documents")

      assert html =~ "Listing Documents"
      assert html =~ document.filename
    end

    test "saves new document", %{conn: conn} do
      project = DocumentPipeline.ProjectsFixtures.project_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/documents")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Document")
               |> render_click()
               |> follow_redirect(conn, ~p"/documents/new")

      assert render(form_live) =~ "New Document"

      assert form_live
             |> form("#document-form", document: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#document-form",
                 document: Map.put(@create_attrs, :project_id, project.id)
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/documents")

      html = render(index_live)
      assert html =~ "Document created successfully"
      assert html =~ "some filename"
    end

    test "updates document in listing", %{conn: conn, document: document} do
      {:ok, index_live, _html} = live(conn, ~p"/documents")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#documents-#{document.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/documents/#{document}/edit")

      assert render(form_live) =~ "Edit Document"

      assert form_live
             |> form("#document-form", document: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#document-form", document: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/documents")

      html = render(index_live)
      assert html =~ "Document updated successfully"
      assert html =~ "some updated filename"
    end

    test "deletes document in listing", %{conn: conn, document: document} do
      {:ok, index_live, _html} = live(conn, ~p"/documents")

      assert index_live |> element("#documents-#{document.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#documents-#{document.id}")
    end
  end

  describe "Show" do
    setup [:create_document]

    test "displays document", %{conn: conn, document: document} do
      {:ok, _show_live, html} = live(conn, ~p"/documents/#{document}")

      assert html =~ "Show Document"
      assert html =~ document.filename
    end

    test "updates document and returns to show", %{conn: conn, document: document} do
      {:ok, show_live, _html} = live(conn, ~p"/documents/#{document}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/documents/#{document}/edit?return_to=show")

      assert render(form_live) =~ "Edit Document"

      assert form_live
             |> form("#document-form", document: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#document-form", document: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/documents/#{document}")

      html = render(show_live)
      assert html =~ "Document updated successfully"
      assert html =~ "some updated filename"
    end
  end
end
