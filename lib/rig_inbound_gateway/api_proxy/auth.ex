defmodule RigInboundGateway.ApiProxy.Auth do
  @moduledoc """
  Authentication check for proxied requests.
  """

  alias RigInboundGateway.ApiProxy.Api
  alias RigInboundGateway.ApiProxy.Auth.Jwt

  # ---

  @spec check(Plug.Conn.t(), Api.t(), Api.endpoint()) :: :ok | {:error, :authentication_failed}
  def check(conn, api, endpoint)

  # Authenticate by JWT:
  def check(
        conn,
        %{"auth_type" => "jwt"} = api,
        %{"secured" => true}
      ),
      do: Jwt.check(conn, api)

  # Skip by default
  def check(_, _, _), do: :ok
end
