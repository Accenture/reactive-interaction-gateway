defmodule RigOutboundGateway.Kinesis.LogStream do
  @moduledoc """
  Converts the Java-client output to Elixir log messages.
  """
  require Logger
  alias __MODULE__

  defstruct buffer: ""

  defimpl Collectable do
    @log_prefix "[KINESIS JAVA-CLIENT] "

    def into(%LogStream{} = original_stream) do
      collector_fn = fn
        stream, {:cont, x} -> handle_input(stream, x)
        stream, _ -> handle_input(stream)
      end

      acc = original_stream
      {acc, collector_fn}
    end

    defp handle_input(stream) do
      # No input, so we've reached the end. Handle remaining input:
      handle_line(stream.buffer)
      %LogStream{buffer: ""}
    end

    defp handle_input(stream, input) do
      buffered_input = stream.buffer <> input

      case String.split(buffered_input, "\n") do
        [_incomplete_line] ->
          # No newline yet -> use as new buffer:
          %LogStream{buffer: buffered_input}

        [line_closing | remainder] ->
          # There is a newline in the stream -> log the line:
          handle_line(line_closing)
          # Set the buffer to the remaining input:
          %LogStream{buffer: Enum.join(remainder)}
      end
    end

    # The log message format is set by the -D parameter to Porcelain.exec below.
    # Here we parse the actual log level out of the message.
    defp handle_line(line) do
      case Regex.named_captures(~r/^(?<level>[^:]+): (?<msg>.+)$/, line) do
        nil -> Logger.error(@log_prefix <> line)
        %{"level" => java_level, "msg" => msg} -> handle_parsed_line(java_level, msg)
      end
    end

    defp handle_parsed_line(java_level, msg) do
      case convert_level(java_level) do
        nil ->
          Logger.error("failed to parse log level #{java_level}")
          Logger.error("#{@log_prefix}#{java_level}: #{msg}")

        elixirLevel ->
          Logger.log(elixirLevel, @log_prefix <> msg)
      end
    end

    defp convert_level("FINE"), do: :debug
    defp convert_level("INFO"), do: :info
    defp convert_level("WARNING"), do: :warn
    defp convert_level("SEVERE"), do: :error
    defp convert_level(_), do: nil
  end
end
