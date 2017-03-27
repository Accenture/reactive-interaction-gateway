defmodule Gateway.Utils.Jwt do
  @moduledoc """
  Provides utility functions over JWT using Joken
  """
  import Joken

  @spec valid?(String.t) :: map
  def valid?(jwt) do
    jwt
    |> token
    |> with_validation("exp", &(&1 > current_time()))
    |> with_signer(hs256(Application.get_env(:gateway, Gateway.Endpoint)[:jwt_key]))
    |> verify!
  end

  @spec user_id(String.t) :: String.t
  def user_id(jwt) do
    with {_status, decoded} <- valid?(jwt) do
      decoded
      |> get_user_id
    end
  end

  @spec get_user_id(map) :: tuple
  defp get_user_id(%{"username" => username}), do: {:ok, username}
  defp get_user_id(_user), do: {:error, "Invalid token"}

end
