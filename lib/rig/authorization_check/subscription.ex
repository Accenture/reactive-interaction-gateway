defmodule RIG.AuthorizationCheck.Subscription do
  @moduledoc """
  Decides whether to allow or reject a subscription request.
  """
  use Rig.Config, :custom_validation

  alias RIG.AuthorizationCheck.External
  alias RIG.AuthorizationCheck.Header
  alias RIG.AuthorizationCheck.Request

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

  # ---

  @spec check_authorization(Request.t()) :: :ok | {:error, :not_authorized}
  def check_authorization(request)

  # If body is nil, there are no subscriptions to authorize.
  def check_authorization(%{body: nil}), do: :ok

  def check_authorization(%Request{} = request) do
    %{validation_type: validation_type} = config()

    case validation_type do
      :no_check ->
        :ok

      :jwt_validation ->
        if Header.any_valid_bearer_token?(request) do
          :ok
        else
          {:error, :not_authorized}
        end

      {:url, base_url} ->
        External.check_or_log(base_url, request)
    end
  end
end
