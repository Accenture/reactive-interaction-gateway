defmodule RigInboundGateway.ApiProxy.Auth do
  @moduledoc """
  Authentication check for proxied requests.
  """

  alias RigInboundGateway.ApiProxy.Api
  alias RigInboundGateway.ApiProxy.Auth.Jwt

  # ---

  @spec check(Plug.Conn.t(), Api.t(), Api.endpoint()) :: :ok | {:error, :authentication_failed}
  def check(conn, api, endpoint)

  # Skip authentication if auth type is not set:
  def check(_, %{"auth_type" => "none"}, _), do: :ok

  # Skip authentication if turned off:
  def check(_, _, %{"secured" => false}), do: :ok

  # Authenticate by JWT:
  def check(
        conn,
        %{"auth_type" => "jwt"} = api,
        %{"secured" => true}
      ),
      do: Jwt.check(conn, api)
end
