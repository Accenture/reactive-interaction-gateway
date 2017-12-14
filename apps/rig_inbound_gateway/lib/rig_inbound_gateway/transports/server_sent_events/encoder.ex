defmodule RigInboundGateway.Transports.ServerSentEvents.Encoder do
  @moduledoc """
  SSE-protocol encoding of messages ready to be sent over the wire.

  """

  @doc false
  def format(%Phoenix.Socket.Message{} = msg) do
    format_id(msg)
    <> format_event(msg)
    <> format_data(msg)
    <> "\n"
  end
  def format(:heartbeat), do: "event: heartbeat\n\n"
  def format(:bye), do: "event: closing connection\n\n"
  # For handling HTTP status codes:
  def format(status) when is_atom(status), do: "event: #{Atom.to_string(status)}\n\n"

  defp format_id(%Phoenix.Socket.Message{ref: ref}) when byte_size(ref) > 0 do
    "id: #{ref}\n"
  end
  defp format_id(_), do: ""

  defp format_event(%Phoenix.Socket.Message{event: event}) when byte_size(event) > 0 do
    "event: #{event}\n"
  end
  defp format_event(_), do: ""

  defp format_data(%Phoenix.Socket.Message{event: "phx_reply"} = msg), do:
    "data: #{msg |> Poison.encode!}\n"
  defp format_data(%Phoenix.Socket.Message{payload: nil}), do:
    ""
  defp format_data(%Phoenix.Socket.Message{payload: payload}), do:
    "data: #{payload |> Poison.encode!}\n"
end
