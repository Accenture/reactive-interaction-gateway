defmodule RigAuth.AuthorizationCheck.Header do
  @moduledoc false

  alias Plug

  alias RIG.JWT
  alias RigAuth.AuthorizationCheck.Request

  # ---

  @spec any_valid_bearer_token?(Request.t()) :: boolean
  def any_valid_bearer_token?(request)

  def any_valid_bearer_token?(%{auth_info: %{auth_tokens: tokens}}) do
    for({"bearer", token} <- tokens, do: JWT.valid?(token))
    |> Enum.any?()
  end

  def any_valid_bearer_token?(_), do: false
end
