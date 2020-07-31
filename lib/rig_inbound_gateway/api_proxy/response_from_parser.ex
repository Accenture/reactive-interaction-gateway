defmodule RigInboundGateway.ApiProxy.ResponseFromParser do
  @moduledoc """
  Handles parsing of messages coming from different sources (e.g. Kafka)

  """

  require Logger

  use Rig.Config, [:schema_registry_host]

  alias Rig.Connection.Codec
  alias RigKafka.Avro

  @default_response_code 200

  # ---

  @spec parse([{String.t(), String.t()}, ...], map()) ::
          {pid, pos_integer(), any(), map()} | String.t()
  # structured
  def parse(
        _headers,
        %{
          "body" => body,
          "rig" => rig_metadata
        } = message
      ) do
    with {:ok, correlation_id} <- Map.fetch(rig_metadata, "correlation"),
         {:ok, deserialized_pid} <- Codec.deserialize(correlation_id),
         raw_response_code <- Map.get(rig_metadata, "response_code", @default_response_code),
         # convert status code to int if needed, HTTP headers can't have number as a value
         {response_code, _} <- to_int(raw_response_code),
         response_headers <- Map.get(message, "headers", %{}),
         response_body <- try_encode(body) do
      Logger.debug(fn ->
        "Parsed structured HTTP response: body=#{inspect(response_body)}, headers=#{
          inspect(response_headers)
        }, code=#{inspect(response_code)}"
      end)

      {deserialized_pid, response_code, response_body, response_headers}
    else
      err -> err
    end
  end

  # binary
  def parse(
        headers,
        message
      ) do
    with headers_map <- Enum.into(headers, %{}),
         {:ok, correlation_id} <- Map.fetch(headers_map, "rig-correlation"),
         {:ok, deserialized_pid} <- Codec.deserialize(correlation_id),
         raw_response_code <- Map.get(headers_map, "rig-response-code", @default_response_code),
         # convert status code to int if needed, HTTP headers can't have number as a value
         {response_code, _} <- to_int(raw_response_code),
         response_body <- try_encode(message) do
      Logger.debug(fn ->
        "Parsed binary HTTP response: body=#{inspect(message)}, code=#{inspect(response_code)}"
      end)

      {deserialized_pid, response_code, response_body, %{}}
    else
      err -> err
    end
  end

  # ---

  @spec try_decode_message(<<_::3>> | String.t()) :: String.t() | map()
  def try_decode_message(<<0::8, _id::32, _body::binary>> = message),
    do: Avro.decode(message, config().schema_registry_host)

  def try_decode_message(message) when is_binary(message) do
    case Jason.decode(message) do
      {:ok, val_map} ->
        val_map

      _ ->
        message
    end
  end

  # ---

  defp try_encode(message) when is_binary(message), do: message

  defp try_encode(message) do
    case Jason.encode(message) do
      {:ok, val_map} ->
        val_map

      _ ->
        message
    end
  end

  # ---

  defp to_int(value) when is_integer(value), do: {value, nil}
  defp to_int(value), do: Integer.parse(value)
end
