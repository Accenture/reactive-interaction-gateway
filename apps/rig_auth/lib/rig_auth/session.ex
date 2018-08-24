defmodule RigAuth.Session do
  @moduledoc """
  Session tracking from authorization-header tokens.
  """
  use Rig.Config, [:jwt_session_field]

  alias Rig.SessionHub
  alias RigAuth.Jwt.Utils, as: Jwt

  @spec update(Plug.Conn.t(), pid()) :: nil
  def update(conn, pid) do
    %{jwt_session_field: jwt_session_field} = config()
    do_update(conn, pid, jwt_session_field)
  end

  defp do_update(_, _, nil), do: nil
  defp do_update(_, _, ""), do: nil

  defp do_update(conn, pid, jwt_session_field) do
    tokens = Map.get(conn.assigns, :auth_tokens, [])

    session_names =
      for {"bearer", token} <- tokens do
        case Jwt.decode(token) do
          {:ok, token_map} -> Map.get(token_map, jwt_session_field)
          _ -> ""
        end
      end
      |> Enum.reject(fn x -> x == "" end)

    for session <- session_names do
      SessionHub.join(pid, session)
    end
  end
end
