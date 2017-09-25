defmodule Gateway.ApiProxy.Plug do
  @moduledoc """
  Module responsible for catching and forwarding all trafix to Proxy Router.
  Possible to do transformations to requests before they get to Proxy Router for
  further processing & forwarding.
  """
  import Plug.Conn

  def init(opts), do: opts
  def call(conn, opts) do
    conn
    |> Gateway.ApiProxy.Router.call(opts)
  end
end
