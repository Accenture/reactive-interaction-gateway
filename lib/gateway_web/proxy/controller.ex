defmodule GatewayWeb.Proxy.Controller do
  @moduledoc """
  HTTP-accessible API for managing PROXY APIs.

  """
  require Logger
  use GatewayWeb, :controller
  alias Gateway.Proxy

  def list_apis(conn, _params) do # TODO: UNIQUE
    apis =
      Proxy
      |> Proxy.list_apis
      |> Enum.map(&(elem(&1, 1)))

    send_response(conn, 200, apis)
  end

  def get_api_detail(conn, params) do # TODO: UNIQUE
    %{"id" => id} = params

    case Proxy.get_api(Proxy, id) do
      nil -> send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
      {_id, api} -> send_response(conn, 200, api)
      _ -> send_response(conn, 500)
    end
  end

  def add_api(conn, params) do
    %{"id" => id} = params

    case Proxy.add_api(Proxy, id, params) do
      {:error, {:already_tracked, _pid, _server, _api_id}} ->
        send_response(conn, 409, %{message: "API with id=#{id} already exists."})
      {:ok, _phx_ref} ->
        send_response(conn, 201, %{message: "ok"})
      _ ->
        send_response(conn, 500)
    end
  end

  def update_api(conn, params) do
    %{"id" => id} = params

    with {_id, current_api} <- Proxy.get_api(Proxy, id),
         {:ok, _phx_ref} <- merge_and_update(id, current_api, params)
    do
      send_response(conn, 200, %{message: "ok"})
    else
      nil -> send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
      _ -> send_response(conn, 500)
    end
  end

  def delete_api(conn, params) do
    %{"id" => id} = params

    with {_id, _current_api} <- Proxy.get_api(Proxy, id),
         :ok <- Proxy.delete_api(Proxy, id)
    do
      send_response(conn, 204)
    else
      nil -> send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
      _ -> send_response(conn, 500)
    end
  end

  defp merge_and_update(id, current_api, updated_api) do
    merged_api = current_api |> Map.merge(updated_api)
    Proxy.update_api(Proxy, id, merged_api)
  end

  defp send_response(conn, status_code, body \\ %{}) do
    conn
    |> put_status(status_code)
    |> json(body)
  end
end
