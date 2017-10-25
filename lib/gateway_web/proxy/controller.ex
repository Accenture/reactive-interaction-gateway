defmodule GatewayWeb.Proxy.Controller do
  @moduledoc """
  HTTP-accessible API for managing PROXY APIs.

  """
  require Logger
  use GatewayWeb, :controller
  @gateway_proxy Application.get_env(:gateway, :gateway_proxy)

  def list_apis(conn, _params) do
    apis =
      @gateway_proxy
      |> @gateway_proxy.list_apis
      |> Enum.map(fn(api) -> elem(api, 1) end)
      |> Enum.filter(fn(api) -> api["active"] == true end)

    send_response(conn, 200, apis)
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

    with nil <- @gateway_proxy.get_api(@gateway_proxy, id),
         {:ok, _phx_ref} <- @gateway_proxy.add_api(@gateway_proxy, id, params)
    do
      send_response(conn, 201, %{message: "ok"})
    else
      {_id, %{"active" => true}} ->
        send_response(conn, 409, %{message: "API with id=#{id} already exists."})
      {_id, %{"active" => false} = prev_api} ->
        {:ok, _phx_ref} = @gateway_proxy |> @gateway_proxy.replace_api(id, prev_api, params)
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

    with {_id, _current_api} <- get_active_api(id),
         {:ok, _phx_ref} <- @gateway_proxy.deactivate_api(@gateway_proxy, id)
    do
      send_response(conn, 204)
    else
      api when api == nil or api == :inactive ->
        send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
    end
  end

  defp get_active_api(id) do
    with {id, current_api} <- @gateway_proxy.get_api(@gateway_proxy, id),
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
    @gateway_proxy.update_api(@gateway_proxy, id, merged_api)
  end

  defp send_response(conn, status_code, body \\ %{}) do
    conn
    |> put_status(status_code)
    |> json(body)
  end
end
