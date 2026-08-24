defmodule DocumentPipeline.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DocumentPipeline.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        address: "some address",
        name: "some name",
        status: "some status",
        total_budget: "120.5"
      })
      |> DocumentPipeline.Projects.create_project()

    project
  end
end
