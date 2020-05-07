defmodule RigInboundGateway.ApiProxy.Api do
  @moduledoc """
  Service definitions for the proxy.

  """

  @type endpoint :: %{
          optional(:secured) => boolean,
          optional(:transform_request_headers) => boolean,
          optional(:target) => String.t(),
          optional(:topic) => String.t(),
          optional(:schema) => String.t(),
          optional(:response_from) => String.t(),
          id: String.t(),
          # Simple matching; curly braces may be used to ignore parts of the URI.
          # Example:
          #     /path/{to}/somewhere/{special} is matched by /path/1/somewhere/2
          path: String.t(),
          # Matches against a regular expression.
          # Note that JSON requires escaping the backslash character.
          # Example:
          #     /path/.+/somewhere/.+ is matched by /path/1/somewhere/2
          path_regex: String.t(),
          # Used to rewrite the request path. When used with `path_regex`, capture
          # groups can be referenced by number.
          # Note that JSON requires escaping the backslash character.
          # Example:
          #     path_regex            : /path/(.+)/somewhere/(.+)
          #     path_replacement      : /somewhere/\1/path/\2
          #     original request path : /path/1/somewhere/2
          #     rewritten request path: /somewhere/1/path/2
          path_replacement: String.t(),
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

  @type endpoint_match :: {t(), endpoint(), request_path :: String.t()}
  @spec filter(api_list(), Plug.Conn.t()) :: [endpoint_match()]

  def filter(apis, %{method: request_method, request_path: request_path}) do
    # "versioned" is not supported yet:
    apis = Enum.reject(apis, fn api -> Map.get(api, "versioned", false) end)

    for api <- apis,
        endpoints = get_in(api, ["version_data", "default", "endpoints"]) || [],
        endpoint <- endpoints,
        endpoint_match_method?(endpoint, request_method) do
      case match_and_rewrite(endpoint, request_path) do
        {:ok, request_path} -> {api, endpoint, request_path}
        :no_match -> :no_match
      end
    end
    |> Enum.reject(&(&1 == :no_match))
  end

  # ---

  defp endpoint_match_method?(endpoint, request_method)

  defp endpoint_match_method?(%{"method" => method}, request_method), do: method == request_method
  defp endpoint_match_method?(_, _), do: false

  # ---

  defp match_and_rewrite(endpoint, request_path) do
    path = Map.get(endpoint, "path")
    path_regex = Map.get(endpoint, "path_regex")
    path_replacement = Map.get(endpoint, "path_replacement")

    %{
      request_path: request_path,
      pattern: nil,
      match?: false,
      rewritten_path: nil
    }
    |> match_by_simple_pattern(path)
    |> match_by_regex_pattern(path_regex)
    |> rewrite_request_path(path_replacement)
    |> case do
      %{match?: true, rewritten_path: nil} -> {:ok, request_path}
      %{match?: true, rewritten_path: rewritten_path} -> {:ok, rewritten_path}
      _ -> :no_match
    end
  end

  # ---

  defp match_by_simple_pattern(state, path)

  defp match_by_simple_pattern(%{request_path: request_path, match?: false} = state, path)
       when byte_size(path) > 0 do
    # Ignore placeholders:
    pattern =
      path
      |> String.replace(~r/\{.*?\}/ui, "[^/]+")
      |> to_anchored_regex()

    if Regex.match?(pattern, request_path),
      do: Map.merge(state, %{match?: true, pattern: pattern}),
      else: state
  end

  defp match_by_simple_pattern(state, _), do: state

  # ---

  defp match_by_regex_pattern(state, pattern)

  defp match_by_regex_pattern(%{request_path: request_path, match?: false} = state, pattern)
       when byte_size(pattern) > 0 do
    pattern = pattern |> to_anchored_regex()

    if Regex.match?(pattern, request_path),
      do: Map.merge(state, %{match?: true, pattern: pattern}),
      else: state
  end

  defp match_by_regex_pattern(state, _), do: state

  # ---

  defp rewrite_request_path(state, replacement)

  defp rewrite_request_path(
         %{request_path: request_path, pattern: pattern, match?: true, rewritten_path: nil} =
           state,
         replacement
       )
       when byte_size(replacement) > 0 do
    rewritten_path = String.replace(request_path, pattern, replacement)
    Map.put(state, :rewritten_path, rewritten_path)
  end

  defp rewrite_request_path(state, _), do: state

  # ---

  defp to_anchored_regex("^" <> pattern) do
    pattern = if pattern |> String.ends_with?("$"), do: pattern, else: "#{pattern}$"
    # u .. unicode
    # i .. caseless
    ~r/#{pattern}/ui
  end

  defp to_anchored_regex(pattern), do: to_anchored_regex("^#{pattern}")
end
