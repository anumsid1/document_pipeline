defmodule DocumentPipelineWeb.DocumentLineItemLiveTest do
  use DocumentPipelineWeb.ConnCase

  import Phoenix.LiveViewTest
  import DocumentPipeline.DocumentsFixtures

  @create_attrs %{
    description: "some description",
    category: "some category",
    amount: "120.5",
    line_number: 42
  }
  @update_attrs %{
    description: "some updated description",
    category: "some updated category",
    amount: "456.7",
    line_number: 43
  }
  @invalid_attrs %{description: nil, category: nil, amount: nil, line_number: nil}
  defp create_document_line_item(_) do
    document_line_item = document_line_item_fixture()

    %{document_line_item: document_line_item}
  end

  describe "Index" do
    setup [:create_document_line_item]

    test "lists all document_line_items", %{conn: conn, document_line_item: document_line_item} do
      {:ok, _index_live, html} = live(conn, ~p"/document_line_items")

      assert html =~ "Listing Document line items"
      assert html =~ document_line_item.description
    end

    test "saves new document_line_item", %{conn: conn} do
      document = DocumentPipeline.DocumentsFixtures.document_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/document_line_items")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Document line item")
               |> render_click()
               |> follow_redirect(conn, ~p"/document_line_items/new")

      assert render(form_live) =~ "New Document line item"

      assert form_live
             |> form("#document_line_item-form", document_line_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#document_line_item-form",
                 document_line_item: Map.put(@create_attrs, :document_id, document.id)
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/document_line_items")

      html = render(index_live)
      assert html =~ "Document line item created successfully"
      assert html =~ "some description"
    end

    test "updates document_line_item in listing", %{
      conn: conn,
      document_line_item: document_line_item
    } do
      {:ok, index_live, _html} = live(conn, ~p"/document_line_items")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#document_line_items-#{document_line_item.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/document_line_items/#{document_line_item}/edit")

      assert render(form_live) =~ "Edit Document line item"

      assert form_live
             |> form("#document_line_item-form", document_line_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#document_line_item-form", document_line_item: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/document_line_items")

      html = render(index_live)
      assert html =~ "Document line item updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes document_line_item in listing", %{
      conn: conn,
      document_line_item: document_line_item
    } do
      {:ok, index_live, _html} = live(conn, ~p"/document_line_items")

      assert index_live
             |> element("#document_line_items-#{document_line_item.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#document_line_items-#{document_line_item.id}")
    end
  end

  describe "Show" do
    setup [:create_document_line_item]

    test "displays document_line_item", %{conn: conn, document_line_item: document_line_item} do
      {:ok, _show_live, html} = live(conn, ~p"/document_line_items/#{document_line_item}")

      assert html =~ "Show Document line item"
      assert html =~ document_line_item.description
    end

    test "updates document_line_item and returns to show", %{
      conn: conn,
      document_line_item: document_line_item
    } do
      {:ok, show_live, _html} = live(conn, ~p"/document_line_items/#{document_line_item}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/document_line_items/#{document_line_item}/edit?return_to=show"
               )

      assert render(form_live) =~ "Edit Document line item"

      assert form_live
             |> form("#document_line_item-form", document_line_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#document_line_item-form", document_line_item: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/document_line_items/#{document_line_item}")

      html = render(show_live)
      assert html =~ "Document line item updated successfully"
      assert html =~ "some updated description"
    end
  end
end
