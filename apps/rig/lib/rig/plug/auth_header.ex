defmodule Rig.Plug.AuthHeader do
  @moduledoc """
  Plug to deal with multiple tokens in the authorization header.
  """
  @behaviour Plug
  alias Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    auth_tokens =
      for {"authorization", val} <- conn.req_headers do
        Conn.Utils.list(val)
        |> Enum.map(fn token ->
          token
          |> String.split(" ", parts: 2)
          |> case do
            [token] -> {"bearer", token}
            [scheme, token] -> {String.downcase(scheme), token}
          end
        end)
      end
      |> Enum.concat()

    Conn.assign(conn, :auth_tokens, auth_tokens)
  end
end
