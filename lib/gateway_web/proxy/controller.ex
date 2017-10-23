defmodule GatewayWeb.Proxy.Controller do
  @moduledoc """
  HTTP-accessible API for managing PROXY APIs.

  """
  require Logger
  use GatewayWeb, :controller
  alias Gateway.Proxy

  def list_apis(conn, _params) do
    apis =
      Proxy
      |> Proxy.list_apis
      |> Enum.map(fn(api) -> elem(api, 1) end)
      |> Enum.filter(fn(api) -> api["active"] == true end)

    send_response(conn, 200, apis)
  end

  def get_api_detail(conn, params) do
    %{"id" => id} = params

    case get_active_api(id) do
      nil -> send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
      :inactive -> send_response(conn, 403, %{message: "Resource with id=#{id} is forbidden."})
      {_id, api} -> send_response(conn, 200, api)
      _ -> send_response(conn, 500)
    end
  end

  def add_api(conn, params) do
    %{"id" => id} = params

    with nil <- Proxy.get_api(Proxy, id),
         {:ok, _phx_ref} <- Proxy.add_api(Proxy, id, params)
    do
      send_response(conn, 201, %{message: "ok"})
    else
      {_id, %{"active" => true}} ->
        send_response(conn, 409, %{message: "API with id=#{id} already exists."})
      {_id, %{"active" => false}} ->
        send_response(conn, 403, %{message: "Resource with id=#{id} is forbidden."})
      _ -> send_response(conn, 500)
    end
  end

  def update_api(conn, params) do
    %{"id" => id} = params

    with {_id, current_api} <- get_active_api(id),
         {:ok, _phx_ref} <- merge_and_update(id, current_api, params)
    do
      send_response(conn, 200, %{message: "ok"})
    else
      nil -> send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
      :inactive -> send_response(conn, 403, %{message: "Resource with id=#{id} is forbidden."})
      _ -> send_response(conn, 500)
    end
  end

  def deactivate_api(conn, params) do
    %{"id" => id} = params

    with {_id, _current_api} <- get_active_api(id),
         {:ok, _phx_ref} <- Proxy.deactivate_api(Proxy, id)
    do
      send_response(conn, 204)
    else
      nil -> send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
      :inactive -> send_response(conn, 403, %{message: "Resource with id=#{id} is forbidden."})
      _ -> send_response(conn, 500)
    end
  end

  defp get_active_api(id) do
    with {id, current_api} <- Proxy.get_api(Proxy, id),
         true <- current_api["active"] == true
    do
      {id, current_api}
    else
      nil -> nil
      false -> :inactive
      _ -> :error
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
