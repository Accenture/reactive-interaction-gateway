defmodule Rig.Connection.Codec do
  @moduledoc """
  Encode and decode a connection token, e.g., for correlation.

  TODO: sign the token - using binary_to_term without signature verification is a threat.
  """

  @doc "Turn a pid into an url-encoded string."
  @spec serialize(pid) :: binary
  def serialize(pid) do
    pid
    |> :erlang.term_to_binary()
    |> Base.encode64()
    |> URI.encode_www_form()

    # TODO sign this
  end

  # ---

  @doc "Convert a serialized string back into a pid."
  @spec deserialize(binary) :: {:ok, pid} | {:error, :not_base64 | :invalid_term}
  def deserialize(url_encoded) do
    # TODO check signature here

    with base64_encoded <- URI.decode_www_form(url_encoded),
         {:ok, decoded_binary} <- decode64(base64_encoded) do
      binary_to_term(decoded_binary)
    end
  end

  # ---

  @doc "Convert a serialized string back into a pid."
  @spec deserialize!(binary) :: pid
  def deserialize!(bin) do
    {:ok, pid} = deserialize(bin)
    pid
  end

  # ---

  @spec decode64(binary()) :: {:ok, binary()} | {:error, :not_base64}
  defp decode64(base64) do
    case Base.decode64(base64) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :not_base64}
    end
  end

  # ---

  @spec binary_to_term(binary()) :: {:ok, term()} | {:error, :invalid_term}
  defp binary_to_term(bin) do
    {:ok, :erlang.binary_to_term(bin, [:safe])}
  rescue
    _ in ArgumentError -> {:error, :invalid_term}
  end
end
