defmodule RigKafka.ProtocolBinding do
  @moduledoc """
  Kafka protocol binding based on the Cloud Events specs:
  https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md
  https://github.com/cloudevents/spec/blob/v1.0/avro-format.md
  """

  alias RigKafka.Serializer

  require Logger

  # --- https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md#32-binary-content-mode

  defp handle_binary_mode(body, headers) do
    ce_headers =
      headers
      |> Enum.filter(&String.starts_with?(elem(&1, 0), "ce-"))
      |> Serializer.remove_prefix()

    binary_mode_message =
      ce_headers
      |> Map.merge(%{"data" => Jason.decode!(body)})
      |> Jason.encode!()

    binary_mode_message
  end

  # --- https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md#33-structured-content-mode

  defp handle_structured_mode(body), do: body

  # ---

  def handle_cloudevent(body, headers, opts) do
    content_type = Enum.find(headers, &(&1 |> elem(0) |> String.downcase() == "content-type"))

    if content_type do
      {_key, content_type_value} = content_type

      # flow based on the https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md#13-content-modes
      case content_type_value do
        "application/cloudevents+avro" <> _suffix ->
          body
          |> Serializer.decode_body!("avro", opts)
          |> handle_binary_mode(headers)

        "application/cloudevents+json" <> _suffix ->
          handle_structured_mode(body)

        "application/cloudevents+" <> invalid_type ->
          {:error, {:unknown_content_type, invalid_type}}

        _ ->
          handle_binary_mode(body, headers)
      end
    else
      case body do
        <<0::8, _id::32, _body::binary>> ->
          Serializer.decode_body!(body, "avro", opts)

        _ ->
          handle_structured_mode(body)
      end
    end
  end
end
