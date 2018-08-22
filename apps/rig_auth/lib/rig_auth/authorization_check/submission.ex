defmodule RigAuth.AuthorizationCheck.Submission do
  @moduledoc """
  Decides whether to accept or deny a request for publishing an event.
  """
  use Rig.Config, :custom_validation

  alias Plug.Conn
  alias Rig.CloudEvent
  alias RigAuth.AuthorizationCheck.Header
  alias RigAuth.AuthorizationCheck.External

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

  @spec check_authorization(Conn.t(), cloud_event :: CloudEvent.t()) ::
          :ok | {:error, :not_authorized}
  def check_authorization(conn, cloud_event) do
    %{validation_type: validation_type} = config()

    case validation_type do
      :no_check ->
        :ok

      :jwt_validation ->
        if Header.any_valid_bearer_token?(conn) do
          :ok
        else
          {:error, :not_authorized}
        end

      {:url, base_url} ->
        params = Map.from_struct(cloud_event)
        External.check_or_log(base_url, conn.req_headers, params)
    end
  end
end
