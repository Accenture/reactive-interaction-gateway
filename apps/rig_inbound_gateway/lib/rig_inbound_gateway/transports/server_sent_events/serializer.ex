defmodule RigInboundGateway.Transports.ServerSentEvents.Serializer do
  @moduledoc """
  Transport serializer for the SSE transport.

  Resembling the structure of the Phoenix LongPoll and WebSocket transports,
  the serializer module takes care of normalizing messages into the Message
  struct.
  """

  @behaviour Phoenix.Transports.Serializer

  alias Phoenix.Socket.Reply
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast

  @doc """
  Translates a `Phoenix.Socket.Broadcast` into a `Phoenix.Socket.Message`.
  """
  def fastlane!(msg = %Broadcast{}) do
    %Message{topic: msg.topic,
             event: msg.event,
             payload: msg.payload}
  end

  @doc """
  Normalizes a `Phoenix.Socket.Message` struct.

  Encoding is handled downstream in the LongPoll controller.
  """
  def encode!(reply = %Reply{}) do
    %Message{
      topic: reply.topic,
      event: "phx_reply",
      ref: reply.ref,
      payload: %{status: reply.status, response: reply.payload}
    }
  end
  def encode!(msg = %Message{}), do: msg

  @doc """
  Decodes JSON String into `Phoenix.Socket.Message` struct.
  """
  def decode!(_message, _opts) do
    Process.exit(self(), "SSE is one-way, so.. wth")
  end
end
