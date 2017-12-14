defmodule RigInboundGatewayWeb.Proxy.Controller do
  @moduledoc """
  HTTP-accessible API for managing PROXY APIs.

  """
  use Rig.Config, [:rig_proxy]
  use RigInboundGatewayWeb, :controller
  require Logger

  def list_apis(conn, _params) do
    %{rig_proxy: proxy} = config()
    api_defs = proxy.list_apis(proxy)
    active_apis = for {_, api} <- api_defs, api["active"], do: api
    send_response(conn, 200, active_apis)
  end

  def get_api_detail(conn, params) do
    %{"id" => id} = params

    case get_active_api(id) do
      api when api == nil or api == :inactive ->
        send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
      {_id, api} -> send_response(conn, 200, api)
    end
  end

  def add_api(conn, params) do
    %{"id" => id} = params
    %{rig_proxy: proxy} = config()

    with nil <- proxy.get_api(proxy, id),
         {:ok, _phx_ref} <- proxy.add_api(proxy, id, params)
    do
      send_response(conn, 201, %{message: "ok"})
    else
      {_id, %{"active" => true}} ->
        send_response(conn, 409, %{message: "API with id=#{id} already exists."})
      {_id, %{"active" => false} = prev_api} ->
        {:ok, _phx_ref} = proxy.replace_api(proxy, id, prev_api, params)
        send_response(conn, 201, %{message: "ok"})
    end
  end

  def update_api(conn, params) do
    %{"id" => id} = params

    with {_id, current_api} <- get_active_api(id),
         {:ok, _phx_ref} <- merge_and_update(id, current_api, params)
    do
      send_response(conn, 200, %{message: "ok"})
    else
      api when api == nil or api == :inactive ->
        send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
    end
  end

  def deactivate_api(conn, params) do
    %{"id" => id} = params
    %{rig_proxy: proxy} = config()

    with {_id, _current_api} <- get_active_api(id),
         {:ok, _phx_ref} <- proxy.deactivate_api(proxy, id)
    do
      send_response(conn, 204)
    else
      api when api == nil or api == :inactive ->
        send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
    end
  end

  defp get_active_api(id) do
    %{rig_proxy: proxy} = config()

    with {id, current_api} <- proxy.get_api(proxy, id),
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
    %{rig_proxy: proxy} = config()
    merged_api = current_api |> Map.merge(updated_api)
    proxy.update_api(proxy, id, merged_api)
  end

  defp send_response(conn, status_code, body \\ %{}) do
    conn
    |> put_status(status_code)
    |> json(body)
  end
end
