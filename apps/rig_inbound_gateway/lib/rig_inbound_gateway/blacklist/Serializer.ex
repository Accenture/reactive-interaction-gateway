defmodule RigInboundGateway.Blacklist.Serializer do
  @moduledoc """
  Serialization for types used in the Blacklist Presence struct.

  """

  @spec serialize_datetime!(Timex.DateTime.t) :: String.t
  def serialize_datetime!(dt) do
    Timex.format!(dt, "{s-epoch}")
  end

  @spec deserialize_datetime!(String.t) :: Timex.DateTime.t
  def deserialize_datetime!(dt) do
    Timex.parse!(dt, "{s-epoch}")
  end
end
