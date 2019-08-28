defmodule RigInboundGateway.ApiProxy.Plug do
  @moduledoc """
  Module responsible for catching and forwarding all trafic to Proxy Router.
  Possible to do transformations to requests before they get to Proxy Router for
  further processing & forwarding.
  """

  def init(opts), do: opts
  def call(conn, opts) do
    conn
    |> RigInboundGateway.ApiProxy.Router.call(opts)
  end
end
