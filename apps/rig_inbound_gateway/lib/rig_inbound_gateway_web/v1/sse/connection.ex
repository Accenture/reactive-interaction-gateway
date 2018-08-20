defmodule RigInboundGatewayWeb.V1.SSE.Connection do
  @moduledoc """
  Connection token for correlating subscriptions with connections.

  TODO: sign the token - using binary_to_term without signature verification is a threat.
  """
  @spec serialize(pid) :: binary
  def serialize(pid) do
    pid
    |> :erlang.term_to_binary()
    |> Base.encode64()

    # TODO sign this
  end

  @spec deserialize(binary) :: {:ok, pid} | {:error, reason :: String.t()}
  def deserialize(bin) do
    # TODO check signature here

    case Base.decode64(bin) do
      {:ok, bin} ->
        pid = :erlang.binary_to_term(bin, [:safe])
        {:ok, pid}

      :error ->
        {:error, :not_base64}
    end
  end
end
