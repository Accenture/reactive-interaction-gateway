defmodule Rig.Connection.Codec do
  @moduledoc """
  Encode and decode a connection token, e.g., for correlation.

  TODO: sign the token - using binary_to_term without signature verification is a threat.
  """
  @spec serialize(pid) :: binary
  def serialize(pid) do
    pid
    |> :erlang.term_to_binary()
    |> Base.encode64()

    # TODO sign this
  end

  @spec deserialize(binary) :: {:ok, pid} | {:error, :not_base64 | :invalid_term}
  def deserialize(bin) do
    # TODO check signature here

    with {:ok, decoded_binary} <- decode64(bin) do
      binary_to_term(decoded_binary)
    end
  end

  @spec decode64(binary()) :: {:ok, binary()} | {:error, :not_base64}
  defp decode64(base64) do
    case Base.decode64(base64) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :not_base64}
    end
  end

  @spec binary_to_term(binary()) :: {:ok, term()} | {:error, :invalid_term}
  defp binary_to_term(bin) do
    {:ok, :erlang.binary_to_term(bin, [:safe])}
  rescue
    _ in ArgumentError -> {:error, :invalid_term}
  end
end
