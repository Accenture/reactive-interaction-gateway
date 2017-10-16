defmodule GatewayWeb.Proxy.Controller do
  @moduledoc """
  HTTP-accessible API for managing PROXY APIs.

  """
  require Logger
  use GatewayWeb, :controller

  # alias GatewayWeb.Endpoint
  alias Gateway.Proxy
  
  # TODO strip internal info from outgoing data

  def list_apis(conn, _params) do
    apis =
      Proxy.list_apis
      |> Enum.map(&(elem(&1, 1)))

    json(conn, apis)
  end

  def add_api(conn, params) do
    IO.inspect params
    %{"id" => id} = params
    IO.puts "DONE"
    new_api = Proxy.add_api(Proxy, id, params)
    IO.inspect new_api

    json(conn, %{"status" => "ok"}) # TODO handle error/success
  end

  def update_api(conn, params) do
    IO.inspect params
    %{"id" => id} = params
    IO.puts "DONE"
    new_api =
      id
      |> Proxy.get_api
      |> elem(1)
      |> Map.merge(params)
    IO.inspect new_api
    upd = Proxy.update_api(Proxy, id, new_api)
    IO.inspect upd

    json(conn, %{"status" => "ok"}) # TODO handle error/success
  end

  def delete_api(conn, params) do
    IO.inspect params
    %{"id" => id} = params
    IO.puts "DONE"
    old_api = Proxy.delete_api(Proxy, id)
    IO.inspect old_api
  
    conn
    |> put_status(204)
    |> json(%{"status" => "ok"}) # TODO handle error/success
  end
end
