defmodule RigInboundGateway.ApiProxy.Serializer do
  @moduledoc """
  Works as (de)serializer/formatter/encoder for API endpoints.
  Abstracts data transformation logic from router logic.
  """

  alias Plug.Conn.Query
  alias RigInboundGateway.Proxy

  @typep headers :: [{String.t, String.t}, ...]

  # Encode error message to JSON
  @spec encode_error_message(String.t) :: %{message: String.t}
  def encode_error_message(message) do
    Poison.encode!(%{message: message})
  end

  # Builds URL where HTTP request should be proxied
  @spec build_url(Proxy.api_definition, String.t) :: String.t
  def build_url(%{"use_env" => true} = proxy, request_path) do
    host = System.get_env(proxy["target_url"]) || "localhost"
    "#{host}:#{proxy["port"]}#{request_path}"
  end
  @spec build_url(Proxy.api_definition, String.t) :: String.t
  def build_url(%{"use_env" => false} = proxy, request_path) do
    "#{proxy["target_url"]}:#{proxy["port"]}#{request_path}"
  end

  # Workaround for HTTPoison/URI.encode not supporting nested query params
  @spec attach_query_params(String.t, %{}) :: String.t
  def attach_query_params(url, params) when params == %{}, do: url
  @spec attach_query_params(String.t, map) :: String.t
  def attach_query_params(url, params) do
    url <> "?" <> Query.encode(params)
  end

  # Search if header has key with given value
  @spec header_value?(headers, String.t, String.t) :: boolean
  def header_value?(headers, key, value) do
    headers
    |> Enum.find({}, fn({header_key, _}) -> header_key == key end)
    |> Tuple.to_list
    |> Enum.member?(value)
  end

  # Transform keys for headers to lower-case
  @spec downcase_headers(headers) :: headers
  def downcase_headers(headers) do
    headers
    |> Enum.map(fn({key, value}) ->
      key_downcase =
        key
        |> String.downcase
      {key_downcase, value}
    end)
  end

  # Add new headers and update existing ones
  @spec add_headers(headers, headers) :: headers
  def add_headers(new_headers, old_headers) do
    old_headers
    |> Enum.filter(fn({old_key, _}) ->
      new_headers
      |> Enum.find(nil, fn({new_key, _}) -> old_key == new_key end)
      |> is_nil
    end)
    |> Enum.concat(new_headers)
  end
end
