defmodule RigApi.V2.MetadataController do
  @moduledoc """
  Handles inbound metadata sets and the indexing and distribution of metadata
  """
  use RigInboundGatewayWeb, :controller

  alias Result
  alias Rig.Connection.Codec
  alias RIG.Plug.BodyReader
  alias RIG.DistributedMap

  @doc """
  
  ### Dirty testing

      FIELD_VALUE="9ab1bff2-a8d8-455c-b48a-50145d7d8e30"
      FIELD_NAME="userid"
      http get ":4010/v2/connection/online?query_value=$FIELD_VALUE&query_field=$FIELD_NAME"
  """
  @spec is_online(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def is_online(%{method: "GET"} = conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    field = conn.query_params["query_field"]
    value = conn.query_params["query_value"]

    online = DistributedMap.get(:metadata, {field, value})
    |> Enum.map(fn x ->
      Codec.deserialize!(x)
    end)
    |> Enum.uniq()
    |> Enum.map(fn x ->
      GenServer.call(x, :is_online)
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
