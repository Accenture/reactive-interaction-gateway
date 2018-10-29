defmodule RigInboundGateway.ApiProxy.Serializer do
  @moduledoc """
  Works as (de)serializer/formatter/encoder for API endpoints.
  Abstracts data transformation logic from router logic.
  """

  alias Plug.Conn.Query
  alias Plug.Conn.Status
  alias RigInboundGateway.Proxy

  @typep headers :: [{String.t(), String.t()}]

  # ---
  # Encode error message to JSON

  @spec encode_error_message(atom | String.t()) :: %{message: String.t()}
  def encode_error_message(status) when is_atom(status) do
    status
    |> Status.code()
    |> encode_error_message()
  end

  def encode_error_message(code) when is_integer(code) do
    code
    |> Status.reason_phrase()
    |> encode_error_message()
  end

  def encode_error_message(message) do
    Poison.encode!(%{message: message})
  end

  # ---

  @spec build_url(Proxy.api_definition() | %URI{}, String.t()) :: String.t()

  def build_url(%URI{} = proxy_uri, request_path) do
    proxy_uri
    |> URI.merge(request_path)
    |> URI.to_string()
  end

  def build_url(%{"use_env" => true, "target_url" => target_url} = proxy, request_path) do
    host = System.get_env(target_url) || "localhost"
    build_url(%{proxy | "target_url" => host, "use_env" => false}, request_path)
  end

  def build_url(%{"target_url" => target_url, "port" => port} = proxy, request_path)
      when is_integer(port) do
    default_scheme = "http"

    {scheme, host} =
      case URI.parse(target_url) do
        %{scheme: nil, host: nil, path: host} -> {default_scheme, host}
        %{scheme: scheme, host: host} -> {scheme, host}
      end

    "#{scheme}://#{host}:#{port}"
    |> URI.parse()
    |> build_url(request_path)
  end

  # ---

  # Workaround for HTTPoison/URI.encode not supporting nested query params
  @spec attach_query_params(String.t(), %{}) :: String.t()
  def attach_query_params(url, params) when params == %{}, do: url
  @spec attach_query_params(String.t(), map) :: String.t()
  def attach_query_params(url, params) do
    url <> "?" <> Query.encode(params)
  end

  # Search if header has key with given value
  @spec header_value?(headers, String.t(), String.t()) :: boolean
  def header_value?(headers, key, value) do
    headers
    |> Enum.find(fn
      {^key, ^value} -> true
      _ -> false
    end)
    |> case do
      nil -> false
      _ -> true
    end
  end

  # Transform keys for headers to lower-case
  @spec downcase_headers(headers) :: headers
  def downcase_headers(headers) do
    headers
    |> Enum.map(fn {key, value} -> {String.downcase(key), value} end)
  end

  # Add new headers and update existing ones
  @spec add_headers(headers, headers) :: headers
  def add_headers(new_headers, old_headers) do
    Map.merge(Map.new(old_headers), Map.new(new_headers))
    |> Enum.to_list()
  end
end
