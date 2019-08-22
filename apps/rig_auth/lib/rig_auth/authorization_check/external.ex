defmodule RigAuth.AuthorizationCheck.External do
  @moduledoc """
  Uses an external endpoint for deciding authorization.
  """
  require Logger
  alias HTTPoison

  alias RigAuth.AuthorizationCheck.Request

  @spec check(url :: String.t(), request :: Request.t()) ::
          true | false | {:error, url :: String.t(), error :: any()}
  def check(url, request) do
    case HTTPoison.post(url, request.body || "", http_headers(request)) do
      {:ok, %HTTPoison.Response{status_code: status}} when status >= 200 and status < 300 -> true
      {:ok, %HTTPoison.Response{status_code: status}} when status == 401 or status == 403 -> false
      {:ok, unexpected_response} -> {:error, unexpected_response}
      {:error, error} -> {:error, {url, error}}
    end
  end

  @spec check_or_log(base_url :: String.t(), request :: Request.t()) ::
          :ok | {:error, :not_authorized}
  def check_or_log(base_url, request) do
    case check(base_url, request) do
      true ->
        :ok

      false ->
        {:error, :not_authorized}

      {:error, response_or_error} ->
        Logger.warn(fn ->
          "authorization check failed: #{inspect(response_or_error)}"
        end)

        {:error, :not_authorized}
    end
  end

  @spec http_headers(request :: Request.t()) :: [{String.t(), String.t()}]
  defp http_headers(request) do
    [{"content-type", request.content_type}] ++
      case request do
        %{auth_info: %{auth_header: auth_header}} -> [{"authorization", auth_header}]
        _ -> []
      end
  end
end
