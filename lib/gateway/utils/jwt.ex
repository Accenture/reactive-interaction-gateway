defmodule Gateway.Utils.Jwt do
  @moduledoc """
  Provides utility functions over JWT using Joken
  """
  import Joken

  @type claim_map :: %{required(String.t) => String.t}

  @spec valid?(String.t) :: boolean
  def valid?(jwt) do
    jwt
    |> validate
    |> get_error == nil
  end

  @spec decode(String.t) :: {:ok, map} | {:error, String.t}
  def decode(jwt) do
    jwt
    |> validate
    |> get_data
  end

  @spec valid_scope?(String.t, String.t, String.t) :: boolean
  def valid_scope?(jwt, namespace, action) do
    jwt
    |> List.first
    |> validate
    |> get_claims
    |> has_valid_scope?(namespace, action)
  end

  @spec validate(String.t) :: map
  defp validate(jwt) do
    jwt
    |> token
    |> with_validation("exp", &(&1 > current_time()))
    |> with_signer(hs256(Application.get_env(:gateway, Gateway.Endpoint)[:jwt_key]))
    |> verify
  end

  @spec has_valid_scope?(nil, String.t, String.t) :: false
  defp has_valid_scope?(nil, _namespace, _action), do: false
  @spec has_valid_scope?(claim_map, String.t, String.t) :: boolean
  defp has_valid_scope?(claims, namespace, action) do
    claims
    |> Map.get("scopes")
    |> Map.get(namespace)
    |> Map.get("actions")
    |> Enum.member?(action)
  end
end
