defimpl Jason.Encoder, for: [Jason.DecodeError] do
  def encode(%{data: data, position: pos, token: token}, opts) do
    maybe_token = if token, do: "token=#{inspect(token)}, ", else: ""
    message = "Failed to decode JSON at position #{pos}: #{maybe_token}data=#{inspect(data)}"
    Jason.Encode.string(message, opts)
  end
end
