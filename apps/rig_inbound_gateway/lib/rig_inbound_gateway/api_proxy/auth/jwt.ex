defmodule RigInboundGateway.ApiProxy.Auth.Jwt do
  @moduledoc """
  JWT based authentication check for proxied requests.
  """

  import Plug.Conn, only: [get_req_header: 2]

  alias RigAuth.Jwt
  alias RigInboundGateway.ApiProxy.Api

  # ---

  def check(conn, api) do
    tokens =
      pick_query_token(conn, api)
      |> Enum.concat(pick_header_token(conn, api))
      |> Enum.reject(&(&1 == ""))

    if Enum.any?(tokens, &Jwt.Utils.valid?/1) do
      :ok
    else
      {:error, :authentication_failed}
    end
  end

  # ---

  # Pick JWT from query parameters
  @spec pick_query_token(Plug.Conn.t(), Api.t()) :: [String.t()]

  defp pick_query_token(conn, %{"auth" => %{"use_query" => true}} = api) do
    conn
    |> Map.get(:query_params)
    |> Map.get(Kernel.get_in(api, ["auth", "query_name"]), "")
    |> String.split()
  end

  defp pick_query_token(_conn, %{"auth" => %{"use_query" => false}}), do: [""]

  # --

  # Pick JWT from headers
  @spec pick_header_token(Plug.Conn.t(), Api.t()) :: [String.t()]

  defp pick_header_token(conn, %{"auth" => %{"use_header" => true}} = api) do
    header_key = Kernel.get_in(api, ["auth", "header_name"]) |> String.downcase()
    get_req_header(conn, header_key)
  end

  defp pick_header_token(_conn, %{"auth" => %{"use_header" => false}}), do: [""]
end
