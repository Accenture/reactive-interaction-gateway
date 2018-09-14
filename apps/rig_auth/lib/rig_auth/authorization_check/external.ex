defmodule RigAuth.AuthorizationCheck.External do
  @moduledoc """
  Uses an external endpoint for deciding authorization.
  """
  require Logger
  alias HTTPoison
  alias Plug.Conn

  @json_mimetype "application/json; charset=utf-8"

  @spec check(url :: String.t(), req_headers :: Conn.headers(), body_params :: map) ::
          true | false | {:error, url :: String.t(), error :: any()}
  def check(url, req_headers, body_params) do
    headers =
      for {"authorization", _} = header <- req_headers,
          into: %{"content-type" => @json_mimetype},
          do: header

    body = Poison.encode!(body_params)

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status}} when status >= 200 and status < 300 -> true
      {:ok, %HTTPoison.Response{status_code: status}} when status == 401 or status == 403 -> false
      {:ok, unexpected_response} -> {:error, unexpected_response}
      {:error, error} -> {:error, {url, error}}
    end
  end

  @spec check_or_log(base_url :: String.t(), req_headers :: Conn.headers(), body_params :: map) ::
          :ok | {:error, :not_authorized}
  def check_or_log(base_url, req_headers, body_params) do
    case check(base_url, req_headers, body_params) do
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
end
