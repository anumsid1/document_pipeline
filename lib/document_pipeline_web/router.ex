defmodule DocumentPipelineWeb.Router do
  use DocumentPipelineWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DocumentPipelineWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DocumentPipelineWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/workspace", WorkspaceLive, :index
    live "/workspace/:project_id", WorkspaceLive, :index

    live "/projects", ProjectLive.Index, :index
    live "/projects/new", ProjectLive.Form, :new
    live "/projects/:id", ProjectLive.Show, :show
    live "/projects/:id/edit", ProjectLive.Form, :edit

    live "/documents", DocumentLive.Index, :index
    live "/documents/new", DocumentLive.Form, :new
    live "/documents/:id", DocumentLive.Show, :show
    live "/documents/:id/edit", DocumentLive.Form, :edit

    live "/document_fields", DocumentFieldLive.Index, :index
    live "/document_fields/new", DocumentFieldLive.Form, :new
    live "/document_fields/:id", DocumentFieldLive.Show, :show
    live "/document_fields/:id/edit", DocumentFieldLive.Form, :edit

    live "/document_line_items", DocumentLineItemLive.Index, :index
    live "/document_line_items/new", DocumentLineItemLive.Form, :new
    live "/document_line_items/:id", DocumentLineItemLive.Show, :show
    live "/document_line_items/:id/edit", DocumentLineItemLive.Form, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", DocumentPipelineWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:document_pipeline, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DocumentPipelineWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
