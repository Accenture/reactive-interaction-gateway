defmodule RigInboundGatewayWeb.Presence.Socket do
  @moduledoc false
  use Phoenix.Socket
  require Logger
  alias RigInboundGateway.Utils.Jwt
  alias RigInboundGateway.Blacklist

  ## Channels
  channel "user:*", RigInboundGatewayWeb.Presence.Channel
  channel "role:*", RigInboundGatewayWeb.Presence.Channel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  transport :longpoll, Phoenix.Transports.LongPoll
  transport :sse, RigInboundGateway.Transports.ServerSentEvents

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(params, socket) do
    with {:ok, raw_token} <- Map.fetch(params, "token"),
         {:ok, token_map} <- Jwt.decode(raw_token),
         :ok <- check_token_not_blacklisted(token_map)
    do
      {:ok, assign(socket, :user_info, token_map)}
    else
      err ->
        Logger.error("Denied UserSocket connect: #{inspect err}")
        :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     RigInboundGatewayWeb.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: Map.get(socket.assigns.user_info, "jti")

  defp check_token_not_blacklisted(%{"jti" => jti}) do
    case Blacklist.contains_jti?(Blacklist, jti) do
      true -> {:error, :blacklisted}
      false -> :ok
    end
  end
end
