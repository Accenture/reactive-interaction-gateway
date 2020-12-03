defmodule RigInboundGateway.ApiProxy.Serializer do
  @moduledoc """
  Works as (de)serializer/formatter/encoder for API endpoints.
  Abstracts data transformation logic from router logic.
  """

  alias Plug.Conn.Status

  # ---
  # Encode error message to JSON

  @spec encode_error_message(atom | String.t()) :: %{message: String.t()}
  def encode_error_message(status) when is_atom(status) do
    status
    |> Status.code()
    |> encode_error_message()
  end

  def encode_error_message(code) when is_integer(code) do
    code
    |> Status.reason_phrase()
    |> encode_error_message()
  end

  def encode_error_message(message) do
    Jason.encode!(%{message: message})
  end
end
