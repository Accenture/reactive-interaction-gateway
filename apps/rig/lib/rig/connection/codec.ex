defmodule Rig.Connection.Codec do
  @moduledoc """
  Encode and decode a connection token, e.g., for correlation.
  """

  @doc "Turn a pid into an url-encoded string."
  @spec serialize(pid) :: binary
  def serialize(pid) do
    key = "7tsf4Y6GTOfPY1iDo4PqZA=="
    pid
    |> :erlang.term_to_binary()
    |> encrypt(key)
    |> Base.url_encode64()
  end

  # ---

  @doc "Convert a serialized string back into a pid."
  @spec deserialize(binary) :: {:ok, pid} | {:error, :not_base64 | :invalid_term}
  def deserialize(base64_encoded) do
    key = "7tsf4Y6GTOfPY1iDo4PqZA=="
    with {:ok, decoded_binary} <- decode64(base64_encoded) do
      decoded_binary
      |> decrypt(key)
      |> binary_to_term()
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

  @doc """
  Encrypts value using key and returns init. vector, ciphertag (MAC) and ciphertext concatenated.
  Additional authenticated data (AAD) adds parameters like protocol version num. to MAC
  """
  @aad "AES256GCM"
  @spec encrypt(binary, binary) :: binary
  def encrypt(val, key) do
    mode = :aes_gcm
    secret_key = :base64.decode(key)
    init_vector = :crypto.strong_rand_bytes(16)
    {ciphertext, ciphertag} = :crypto.block_encrypt(mode, secret_key, init_vector, {@aad, to_string(val), 16})
    init_vector <> ciphertag <> ciphertext
  end

  # ---

  @doc """
  Decrypts ciphertext using key.
  Ciphertext is init. vector, ciphertag (MAC) and the actual ciphertext concatenated.
  """
  @spec encrypt(binary, binary) :: binary
  def decrypt(ciphertext, key) do
    mode = :aes_gcm
    secret_key = :base64.decode(key)
    <<init_vector::binary-16, tag::binary-16, ciphertext::binary>> = ciphertext
    :crypto.block_decrypt(mode, secret_key, init_vector, {@aad, ciphertext, tag})
  end

  # ---

  @spec decode64(binary()) :: {:ok, binary()} | {:error, :not_base64}
  defp decode64(base64) do
    case Base.url_decode64(base64) do
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
