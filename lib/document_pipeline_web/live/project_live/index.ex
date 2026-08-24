defmodule DocumentPipelineWeb.ProjectLive.Index do
  use DocumentPipelineWeb, :live_view

  alias DocumentPipeline.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Projects
        <:actions>
          <.button variant="primary" navigate={~p"/projects/new"}>
            <.icon name="hero-plus" /> New Project
          </.button>
        </:actions>
      </.header>

      <.table
        id="projects"
        rows={@streams.projects}
        row_click={fn {_id, project} -> JS.navigate(~p"/projects/#{project}") end}
      >
        <:col :let={{_id, project}} label="Name">{project.name}</:col>
        <:col :let={{_id, project}} label="Address">{project.address}</:col>
        <:col :let={{_id, project}} label="Total budget">{project.total_budget}</:col>
        <:col :let={{_id, project}} label="Status">{project.status}</:col>
        <:action :let={{_id, project}}>
          <div class="sr-only">
            <.link navigate={~p"/projects/#{project}"}>Show</.link>
          </div>
          <.link navigate={~p"/projects/#{project}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, project}}>
          <.link
            phx-click={JS.push("delete", value: %{id: project.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Projects")
     |> stream(:projects, list_projects())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Projects.get_project(id) do
      {:ok, project} ->
        {:ok, _} = Projects.delete_project(project)
        {:noreply, stream_delete(socket, :projects, project)}

      {:error, :not_found} ->
        {:noreply, socket}
    end
  end

  defp list_projects() do
    Projects.list_projects()
  end
end
