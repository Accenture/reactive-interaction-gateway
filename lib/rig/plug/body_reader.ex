defmodule RIG.Plug.BodyReader do
  @moduledoc """
  Utility module for obtaining a request body.
  """
  alias Plug.Conn

  @doc "Reads a request body as a whole, invoking `Plug.Conn.read_body/2` as often as needed."
  def read_full_body(conn), do: do_read_full_body(conn, "")

  defp do_read_full_body(conn, body_so_far) do
    case Conn.read_body(conn) do
      {:ok, chunk, conn} -> {:ok, body_so_far <> chunk, conn}
      {:more, chunk, conn} -> do_read_full_body(conn, body_so_far <> chunk)
      {:error, _} = error -> error
    end
  end
end
