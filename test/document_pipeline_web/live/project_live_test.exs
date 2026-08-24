defmodule DocumentPipelineWeb.ProjectLiveTest do
  use DocumentPipelineWeb.ConnCase

  import Phoenix.LiveViewTest
  import DocumentPipeline.ProjectsFixtures

  @create_attrs %{
    name: "some name",
    status: "some status",
    address: "some address",
    total_budget: "120.5"
  }
  @update_attrs %{
    name: "some updated name",
    status: "some updated status",
    address: "some updated address",
    total_budget: "456.7"
  }
  @invalid_attrs %{name: nil, status: nil, address: nil, total_budget: nil}
  defp create_project(_) do
    project = project_fixture()

    %{project: project}
  end

  describe "Index" do
    setup [:create_project]

    test "lists all projects", %{conn: conn, project: project} do
      {:ok, _index_live, html} = live(conn, ~p"/projects")

      assert html =~ "Listing Projects"
      assert html =~ project.name
    end

    test "saves new project", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Project")
               |> render_click()
               |> follow_redirect(conn, ~p"/projects/new")

      assert render(form_live) =~ "New Project"

      assert form_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#project-form", project: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/projects")

      html = render(index_live)
      assert html =~ "Project created successfully"
      assert html =~ "some name"
    end

    test "updates project in listing", %{conn: conn, project: project} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#projects-#{project.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/projects/#{project}/edit")

      assert render(form_live) =~ "Edit Project"

      assert form_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#project-form", project: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/projects")

      html = render(index_live)
      assert html =~ "Project updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes project in listing", %{conn: conn, project: project} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert index_live |> element("#projects-#{project.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#projects-#{project.id}")
    end
  end

  describe "Show" do
    setup [:create_project]

    test "displays project", %{conn: conn, project: project} do
      {:ok, _show_live, html} = live(conn, ~p"/projects/#{project}")

      assert html =~ "Show Project"
      assert html =~ project.name
    end

    test "updates project and returns to show", %{conn: conn, project: project} do
      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/projects/#{project}/edit?return_to=show")

      assert render(form_live) =~ "Edit Project"

      assert form_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#project-form", project: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/projects/#{project}")

      html = render(show_live)
      assert html =~ "Project updated successfully"
      assert html =~ "some updated name"
    end
  end
end
