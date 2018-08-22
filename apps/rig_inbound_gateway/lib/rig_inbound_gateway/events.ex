defmodule RigInboundGateway.Events do
  @moduledoc """
  Utility functions used in more than one controller.
  """
  alias Rig.CloudEvent
  alias RigInboundGateway.Connection

  @json_mimetype "application/json; charset=utf-8"

  @spec welcome_event() :: CloudEvent.t()
  def welcome_event do
    connection_pid = self()
    connection_token = Connection.serialize(connection_pid)
    data = %{connection_token: connection_token}
    encoded_data = data |> Poison.encode!()

    CloudEvent.new("rig.connection.create", "rig")
    |> CloudEvent.with_data(@json_mimetype, encoded_data)
  end
end
