defmodule DocumentPipelineWeb.PageController do
  use DocumentPipelineWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
