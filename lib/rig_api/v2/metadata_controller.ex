defmodule RigApi.V2.MetadataController do
  @moduledoc """
  Handles inbound metadata sets and the indexing and distribution of metadata
  """
  use RigInboundGatewayWeb, :controller

  alias Result
  alias Rig.Connection.Codec
  alias RIG.DistributedMap
  alias RIG.Plug.BodyReader

  @doc """
  
  ### Dirty testing

      FIELD_VALUE="9ab1bff2-a8d8-455c-b48a-50145d7d8e30"
      FIELD_NAME="userid"
      # Find specific user
      http get ":4010/v2/connection/online?query_value=$FIELD_VALUE&query_field=$FIELD_NAME"

      # Find all online users
      http get ":4010/v2/connection/online?query_field=$FIELD_NAME"
  """
  @spec is_online(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def is_online(%{method: "GET"} = conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    field = conn.query_params["query_field"]
    value = conn.query_params["query_value"]

    if field == nil do
      send_resp(conn, :bad_request, "")
    else
      if value == nil do
        # Return all online statuses

        # Say we use a userid as our indexed key,
        # Since every user can have multiple open connections
        # And these connection can be stored multiple times in the ETS table (during a refresh)
        # We need this pipeline to first get all the userid-connection_token pairs
        # Then deserialize the connection_tokens so we can then de-duplicate them
        # Then we can group the userids (since only one connection has to be up for
        # the userid to have the status online)
        # Then we filter out all the userids that are offline and remove the second
        # element of the tuple (the online status, which is a bool)

        online = DistributedMap.get_all(:metadata, field)
        # Deserialize connection tokens
        |> Enum.map(fn {key, x} ->
          {key, Codec.deserialize!(x)}
        end)
        # Remove duplicate connection tokens
        |> Enum.uniq
        # Group by key value (e.g. userid)
        |> Enum.group_by(
          fn {x, _y} ->
            x
          end,
          fn {_x, y} ->
            y
          end)
        # Look if any socket of one key is online
        |> Enum.map(fn {key, pids} ->
          {
            key,
            pids
            |> Enum.map(fn pid ->
              try do
                GenServer.call(pid, :is_online)
              catch
                :exit, _ -> false
              end
            end)
            |> Enum.any?(fn x ->
              x
            end)
          }
        end)
        # Filter out offline connections
        |> Enum.filter(fn {_key, is_online?} ->
          is_online?
        end)
        # Get keys of online connections
        |> Enum.map(fn {key, is_online?} ->
          key
        end)

        send_resp(conn, :ok, Jason.encode!(online))
      else
        # Return online status of specific user

        online = DistributedMap.get(:metadata, {field, value})
        |> Enum.map(fn x ->
          Codec.deserialize!(x)
        end)
        |> Enum.uniq()
        |> Enum.map(fn x ->
          try do
            GenServer.call(x, :is_online)
          catch
            :exit, _ -> false
          end
        end)
        |> Enum.any?(fn x ->
          x
        end)

        if online do
          send_resp(conn, :ok, "online")
        else
          send_resp(conn, :ok, "offline")
        end
      end
    end
  end

    @doc """
  
  ### Dirty testing

      FIELD_VALUE="9ab1bff2-a8d8-455c-b48a-50145d7d8e30"
      FIELD_NAME="userid"
      http get ":4010/v2/connection/metadata?query_value=$FIELD_VALUE&query_field=$FIELD_NAME"
  """
  def get_metadata(%{method: "GET"} = conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    field = conn.query_params["query_field"]
    value = conn.query_params["query_value"]

    if field == nil or value == nil do
      send_resp(conn, :bad_request, "")
    else
      data = DistributedMap.get(:metadata, {field, value})
      |> Enum.map(fn x ->
        Codec.deserialize!(x)
      end)
      |> Enum.uniq()
      |> Enum.map(fn x ->
        try do
          GenServer.call(x, :get_metadata)
        catch
          :exit, _ -> nil
        end
      end)
      |> Enum.filter(fn x ->
        x != nil
      end)
      #HACK: In CI, RIG sometimes returns duplicate data
      #I cannot reproduce this on my machine but this fixes it.
      |> Enum.uniq()

      send_resp(conn, :ok, Jason.encode!(data))
    end
  end
end
