defmodule RigInboundGateway.ApiProxy.Auth.Jwt do
  @moduledoc """
  JWT based authentication check for proxied requests.
  """

  import Plug.Conn, only: [get_req_header: 2]

  alias RIG.JWT
  alias RigInboundGateway.ApiProxy.Api

  # ---

  def check(conn, api) do
    valid_tokens =
      tokens_from_query_params(conn, api) ++
        tokens_from_req_header(conn, api)

    case valid_tokens do
      [] -> {:error, :authentication_failed}
      _ -> :ok
    end
  end

  # ---

  # Find and parse JWTs in request query params.
  @spec tokens_from_query_params(Plug.Conn.t(), Api.t()) :: [JWT.claims()]

  defp tokens_from_query_params(conn, %{"auth" => %{"use_query" => true}} = api) do
    selected_param = get_in(api, ["auth", "query_name"])
    tokens_string = Map.get(conn.query_params, selected_param, "")

    tokens_string
    |> String.split(",", trim: true)
    |> Enum.map(&JWT.parse_token/1)
    |> Result.filter_and_unwrap()
  end

  defp tokens_from_query_params(_conn, _), do: []

  # --

  # Find and parse JWTs in request headers.
  @spec tokens_from_req_header(Plug.Conn.t(), Api.t()) :: [JWT.claims()]

  defp tokens_from_req_header(conn, %{"auth" => %{"use_header" => true}} = api) do
    selected_auth_header = get_in(api, ["auth", "header_name"]) |> String.downcase()

    case selected_auth_header do
      "authorization" ->
        JWT.parse_http_header(conn.req_headers)
        |> Result.filter_and_unwrap()

      "x-" <> _ = custom_header ->
        conn
        |> get_req_header(custom_header)
        |> Enum.map(&JWT.parse_token/1)
        |> Result.filter_and_unwrap()
    end
  end

  defp tokens_from_req_header(_conn, _), do: []
end
