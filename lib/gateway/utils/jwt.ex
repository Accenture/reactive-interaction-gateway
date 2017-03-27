defmodule Gateway.Utils.Jwt do
  @moduledoc """
  Provides utility functions over JWT using Joken
  """
  import Joken

  @spec valid?(String.t) :: boolean
  def valid?(token) do
    token
    |> decode
    |> get_error == nil
  end

  @spec user_id(String.t) :: String.t
  def user_id(token) do
    token
    |> decode
    |> get_claims
    |> Map.get("username")
  end

  @spec decode(String.t) :: map
  defp decode (token) do
    token
    |> token
    |> with_validation("exp", &(&1 > current_time()))
    |> with_signer(hs256(Application.get_env(:gateway, Gateway.Endpoint)[:jwt_key]))
    |> verify
  end
end
