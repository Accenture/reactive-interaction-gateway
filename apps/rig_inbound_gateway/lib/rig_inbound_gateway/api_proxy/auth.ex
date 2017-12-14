defmodule RigInboundGateway.ApiProxy.Auth do
  @moduledoc """
  Provides functions for authentication and authorization of API endpoints.
  Abstracts auth based logic from router logic.
  """

  import Plug.Conn, only: [get_req_header: 2]

  alias RigInboundGateway.Utils.Jwt
  alias RigInboundGateway.Proxy

  # Pick JWT from query parameters
  @spec pick_query_token(%Plug.Conn{}, Proxy.api_definition) :: [String.t, ...]
  def pick_query_token(conn, api = %{"auth" => %{"use_query" => true}}) do
    conn
    |> Map.get(:query_params)
    |> Map.get(Kernel.get_in(api, ["auth", "query_name"]), "")
    |> String.split
  end
  @spec pick_query_token(%Plug.Conn{}, Proxy.api_definition) :: []
  def pick_query_token(_conn, %{"auth" => %{"use_query" => false}}), do: [""]

  # Pick JWT from headers
  @spec pick_header_token(%Plug.Conn{}, Proxy.api_definition) :: [String.t, ...]
  def pick_header_token(conn, api = %{"auth" => %{"use_header" => true}}) do
    header_key = Kernel.get_in(api, ["auth", "header_name"]) |> String.downcase
    get_req_header(conn, header_key)
  end
  @spec pick_header_token(%Plug.Conn{}, Proxy.api_definition) :: []
  def pick_header_token(_conn, %{"auth" => %{"use_header" => false}}), do: [""]

  # Validate if any of JWT are valid
  @spec any_token_valid?([]) :: false
  def any_token_valid?([]), do: false
  @spec any_token_valid?([String.t, ...]) :: boolean
  def any_token_valid?(tokens) do
    tokens |> Enum.any?(&Jwt.valid?/1)
  end
end
