defmodule Gateway.Utils.Jwt do
  @moduledoc """
  Provides utility functions over JWT using Joken
  """
  import Joken

  @spec valid?(String.t) :: boolean
  def valid?(jwt) do
    jwt
    |> validate
    |> get_error == nil
  end

  @spec decode(String.t) :: map
  def decode(jwt) do
    jwt
    |> validate
    |> get_data
    |> elem(1)
  end

  @spec validate(String.t) :: map
  defp validate(jwt) do
    jwt
    |> token
    |> with_validation("exp", &(&1 > current_time()))
    |> with_signer(hs256(Application.get_env(:gateway, Gateway.Endpoint)[:jwt_key]))
    |> verify
  end
end
