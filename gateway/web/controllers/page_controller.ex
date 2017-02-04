defmodule Gateway.PageController do
  use Gateway.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
