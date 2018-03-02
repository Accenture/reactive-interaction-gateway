defmodule RigOutboundGateway.Logger do
  @moduledoc false
  require Logger

  # Must be >15, see `trunc_body/1`:
  @max_body_print_length 200

  @spec log(:ok, module(), keyword()) :: any()
  def log(:ok, mod, info) do
    Logger.debug(fn ->
      msg = "Message via #{inspect(mod)}"
      {msg, info |> trunc_body()}
    end)
  end

  @spec log({:error, any()}, module(), keyword()) :: any
  def log(err, mod, info) do
    Logger.warn(fn ->
      msg = "Message via #{inspect(mod)} not accepted: #{inspect(err)}"
      {msg, info |> trunc_body()}
    end)
  end

  def trunc_body(info) do
    body = info |> Keyword.fetch!(:body_raw)

    printable =
      if String.length(body) > @max_body_print_length do
        truncated = String.slice(body, 0..(@max_body_print_length - 15))
        "'#{truncated}' (truncated)"
      else
        body
      end

    Keyword.put_new(info, :body_truncated, printable)
  end
end
