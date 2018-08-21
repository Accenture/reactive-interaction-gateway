defmodule RigInboundGateway.SubscriptionCheck do
  @moduledoc """
  Confex value resolution for the subscription check setting.
  """
  require Logger
  use Rig.Config, :custom_validation

  alias HTTPoison

  # Confex callback
  defp validate_config!(config) do
    validation_type =
      config
      |> Keyword.fetch!(:validation_type)
      |> String.downcase()
      |> case do
        "" -> :no_check
        "no_check" -> :no_check
        "jwt_validation" -> :jwt_validation
        url -> {:url, url}
      end

    %{
      validation_type: validation_type
    }
  end

  @spec check_authorization(Plug.Conn.t(), event_type :: String.t(), recursive? :: boolean) ::
          :ok | {:error, :not_authorized}
  def check_authorization(conn, event_type, recursive?) do
    conf = config()
    do_check_authorization(conf.validation_type, conn, event_type, recursive?)
  end

  defp do_check_authorization(:no_check, _, _, _), do: :ok

  defp do_check_authorization(:jwt_validation, _conn, _, _) do
    raise "jwt_validation not implemented"
  end

  defp do_check_authorization({:url, base_url}, conn, event_type, recursive?) do
    query_params = %{event_type: event_type, recursive: recursive?}
    url = base_url <> "?" <> URI.encode_query(query_params)
    headers = for {"authorization", _} = header <- conn.req_headers, into: %{}, do: header

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> :ok
      {:ok, _} -> {:error, :not_authorized}
      {:error, error_response} -> {:error, :request_failed, url, error_response}
    end
  end
end
