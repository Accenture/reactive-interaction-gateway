defmodule Gateway.ChannelsController do
  use Gateway.Web, :controller
  alias Gateway.PresenceChannel
  alias Gateway.Endpoint
  alias Gateway.Blacklist

  def list_channels(conn, _params) do
    channels =
      "role:customer"
      |> PresenceChannel.channels_list
      |> Map.keys

    json(conn, channels)
  end

  def list_channel_connections(conn, params) do
    %{"id" => id} = params

    connections =
      "user:#{id}"
      |> PresenceChannel.channels_list
      |> Enum.map(fn(user) -> elem(user, 1).metas end)
      |> List.flatten

    json(conn, connections)
  end

  def disconnect_channel_connection(conn, %{"jti" => jti}) do
    Blacklist.add_jti(
      Blacklist,
      jti,
      _expiry =
        get_req_header(conn, "authorization")
        |> extract_jti_expiration
    )
    Endpoint.broadcast(jti, "disconnect", %{})

    conn
    |> put_status(204)
    |> json(%{})
  end

  defp extract_jti_expiration(authorization_tokens) do
    authorization_tokens
    # Try to decode the tokens:
    |> Stream.map(&Gateway.Utils.Jwt.decode/1)
    # If successful, map it to the stringified expiry timestamp:
    |> Stream.map(
      fn
        {:ok, %{"exp" => exp}} -> inspect(exp)  # comes as int, convert to string
        _ -> nil
      end
    )
    # Reject any invalid tokens:
    |> Stream.reject(&is_nil/1)
    # Convert expiration timestamps into Timex structs:
    |> Stream.map(
      fn exp ->
        case Timex.parse(exp, "{s-epoch}") do
          {:ok, timestamp} -> timestamp
          _ -> nil
        end
      end
    )
    # Reject any invalid timestamps:
    |> Stream.reject(&is_nil/1)
    # Use only the first:
    |> Stream.take(1)
    # Stop being lazy:
    |> Enum.to_list
    |> List.first
  end
end
