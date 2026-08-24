defmodule DocumentPipeline.ProjectsTest do
  use DocumentPipeline.DataCase

  alias DocumentPipeline.Projects

  describe "projects" do
    alias DocumentPipeline.Projects.Project

    import DocumentPipeline.ProjectsFixtures

    @invalid_attrs %{name: nil, status: nil, address: nil, total_budget: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Projects.list_projects() == [project]
    end

    test "get_project/1 returns the project with given id" do
      project = project_fixture()
      assert Projects.get_project(project.id) == {:ok, project}
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{
        name: "some name",
        status: "some status",
        address: "some address",
        total_budget: "120.5"
      }

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.name == "some name"
      assert project.status == "some status"
      assert project.address == "some address"
      assert project.total_budget == Decimal.new("120.5")
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()

      update_attrs = %{
        name: "some updated name",
        status: "some updated status",
        address: "some updated address",
        total_budget: "456.7"
      }

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)
      assert project.name == "some updated name"
      assert project.status == "some updated status"
      assert project.address == "some updated address"
      assert project.total_budget == Decimal.new("456.7")
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert Projects.get_project(project.id) == {:ok, project}
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert Projects.get_project(project.id) == {:error, :not_found}
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end
end
