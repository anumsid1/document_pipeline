defmodule DocumentPipelineWeb.DocumentFieldLiveTest do
  use DocumentPipelineWeb.ConnCase

  import Phoenix.LiveViewTest
  import DocumentPipeline.DocumentsFixtures

  @create_attrs %{
    field_value: "some field_value",
    source: "some source",
    field_name: "some field_name",
    confidence: 120.5
  }
  @update_attrs %{
    field_value: "some updated field_value",
    source: "some updated source",
    field_name: "some updated field_name",
    confidence: 456.7
  }
  @invalid_attrs %{field_value: nil, source: nil, field_name: nil, confidence: nil}
  defp create_document_field(_) do
    document_field = document_field_fixture()

    %{document_field: document_field}
  end

  describe "Index" do
    setup [:create_document_field]

    test "lists all document_fields", %{conn: conn, document_field: document_field} do
      {:ok, _index_live, html} = live(conn, ~p"/document_fields")

      assert html =~ "Listing Document fields"
      assert html =~ document_field.field_name
    end

    test "saves new document_field", %{conn: conn} do
      document = DocumentPipeline.DocumentsFixtures.document_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/document_fields")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Document field")
               |> render_click()
               |> follow_redirect(conn, ~p"/document_fields/new")

      assert render(form_live) =~ "New Document field"

      assert form_live
             |> form("#document_field-form", document_field: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#document_field-form",
                 document_field: Map.put(@create_attrs, :document_id, document.id)
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/document_fields")

      html = render(index_live)
      assert html =~ "Document field created successfully"
      assert html =~ "some field_name"
    end

    test "updates document_field in listing", %{conn: conn, document_field: document_field} do
      {:ok, index_live, _html} = live(conn, ~p"/document_fields")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#document_fields-#{document_field.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/document_fields/#{document_field}/edit")

      assert render(form_live) =~ "Edit Document field"

      assert form_live
             |> form("#document_field-form", document_field: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#document_field-form", document_field: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/document_fields")

      html = render(index_live)
      assert html =~ "Document field updated successfully"
      assert html =~ "some updated field_name"
    end

    test "deletes document_field in listing", %{conn: conn, document_field: document_field} do
      {:ok, index_live, _html} = live(conn, ~p"/document_fields")

      assert index_live
             |> element("#document_fields-#{document_field.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#document_fields-#{document_field.id}")
    end
  end

  describe "Show" do
    setup [:create_document_field]

    test "displays document_field", %{conn: conn, document_field: document_field} do
      {:ok, _show_live, html} = live(conn, ~p"/document_fields/#{document_field}")

      assert html =~ "Show Document field"
      assert html =~ document_field.field_name
    end

    test "updates document_field and returns to show", %{
      conn: conn,
      document_field: document_field
    } do
      {:ok, show_live, _html} = live(conn, ~p"/document_fields/#{document_field}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/document_fields/#{document_field}/edit?return_to=show"
               )

      assert render(form_live) =~ "Edit Document field"

      assert form_live
             |> form("#document_field-form", document_field: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#document_field-form", document_field: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/document_fields/#{document_field}")

      html = render(show_live)
      assert html =~ "Document field updated successfully"
      assert html =~ "some updated field_name"
    end
  end
end
