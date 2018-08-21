defmodule Rig.Plug.AuthHeader do
  @moduledoc """
  Plug to deal with multiple tokens in the authorization header.
  """
  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    authorization_tokens =
      for {"authorization", val} <- conn.req_headers do
        # Multiple tokens might be given as a comma-separated list:
        val
        |> String.split(",")
        |> Enum.map(&String.trim/1)
      end
      |> Enum.concat()

    Plug.Conn.assign(conn, :authorization_tokens, authorization_tokens)
  end
end
