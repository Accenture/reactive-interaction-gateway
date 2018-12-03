defmodule RigInboundGateway.ApiProxy.Api do
  @moduledoc """
  Service definitions for the proxy.

  """

  @type endpoint :: %{
          optional(:not_secured) => boolean,
          optional(:transform_request_headers) => boolean,
          optional(:type) => String.t(),
          optional(:target) => String.t(),
          id: String.t(),
          path: String.t(),
          method: String.t()
        }

  @type t :: %{
          optional(:auth_type) => String.t(),
          optional(:versioned) => boolean,
          optional(:active) => boolean,
          optional(:node_name) => atom,
          optional(:ref_number) => integer,
          optional(:timestamp) => DateTime,
          optional(:transform_request_headers) => %{
            optional(:add_headers) => %{
              optional(String.t()) => String.t()
            }
          },
          id: String.t(),
          name: String.t(),
          auth: %{
            optional(:use_header) => boolean,
            optional(:header_name) => String.t(),
            optional(:use_query) => boolean,
            optional(:query_name) => String.t()
          },
          version_data: %{
            optional(String.t()) => %{
              endpoints: [endpoint]
            }
          },
          proxy: %{
            optional(:use_env) => boolean,
            target_url: String.t(),
            port: integer
          }
        }

  @type api_list :: [t]

  # ---

  @type endpoint_match :: {Proxy.api_definition(), Proxy.endpoint()}
  @spec filter(api_list(), Plug.Conn.t()) :: [endpoint_match()]

  def filter(apis, %{method: request_method, request_path: request_path}) do
    # "versioned" is not supported yet:
    apis = Enum.reject(apis, fn api -> Map.get(api, "versioned", false) end)

    endpoint_match? = fn endpoint -> endpoint_match?(endpoint, request_method, request_path) end

    for api <- apis,
        endpoints = get_in(api, ["version_data", "default", "endpoints"]) || [],
        endpoint <- endpoints,
        endpoint_match?.(endpoint) do
      {api, endpoint}
    end
  end

  # ---

  defp endpoint_match?(endpoint_spec, request_method, request_path) do
    endpoint_match_method?(endpoint_spec, request_method) and
      endpoint_match_path?(endpoint_spec, request_path)
  end

  # ---

  defp endpoint_match_method?(endpoint, request_method)

  defp endpoint_match_method?(%{"method" => method}, request_method), do: method == request_method
  defp endpoint_match_method?(_, _), do: false

  # ---

  defp endpoint_match_path?(endpoint, request_path)

  defp endpoint_match_path?(%{"path" => endpoint_path}, request_path) do
    # Ignore placeholders:
    endpoint_path_regex = String.replace(endpoint_path, ~r/\{.*?\}/, "[^/]+")
    String.match?(request_path, ~r/^#{endpoint_path_regex}$/)
  end

  defp endpoint_match_path?(_, _), do: false
end
