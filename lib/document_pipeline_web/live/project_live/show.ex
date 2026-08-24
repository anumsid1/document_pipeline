defmodule DocumentPipelineWeb.ProjectLive.Show do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Project {@project.id}
        <:subtitle>This is a project record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/projects"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/projects/#{@project}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit project
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@project.name}</:item>
        <:item title="Address">{@project.address}</:item>
        <:item title="Total budget">{@project.total_budget}</:item>
        <:item title="Status">{@project.status}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Projects.get_project(id) do
      {:ok, project} ->
        {:ok,
         socket
         |> assign(:page_title, "Show Project")
         |> assign(:project, project)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Project not found")
         |> push_navigate(to: ~p"/projects")}
    end
  end
end
