defmodule RigAuth.AuthorizationCheck.Header do
  @moduledoc false

  alias Plug
  alias RigAuth.Jwt.Utils, as: Jwt

  @spec any_valid_bearer_token?(Conn.t()) :: boolean
  def any_valid_bearer_token?(conn) do
    tokens = Map.get(conn.assigns, :authorization_tokens, [])

    for "Bearer " <> token <- tokens do
      Jwt.valid?(token)
    end
    |> Enum.any?()
  end
end
