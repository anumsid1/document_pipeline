defmodule DocumentPipeline.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias DocumentPipeline.Repo

  alias DocumentPipeline.Projects.Project

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Project
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single project.

  Returns `{:error, :not_found}` if the Project does not exist.

  ## Examples

      iex> get_project(123)
      {:ok, %Project{}}

      iex> get_project(456)
      {:error, :not_found}

  """
  def get_project(id) do
    case Repo.get(Project, id) do
      nil -> {:error, :not_found}
      project -> {:ok, project}
    end
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  def get_project_with_documents(id) do
    Project
    |> preload(documents: [:document_fields, :document_line_items])
    |> Repo.get(id)
    |> case do
      nil -> {:error, :not_found}
      project -> {:ok, project}
    end
  end
end
