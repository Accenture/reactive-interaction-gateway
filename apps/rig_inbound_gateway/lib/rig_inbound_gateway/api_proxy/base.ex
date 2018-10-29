defmodule RigInboundGateway.ApiProxy.Base do
  @moduledoc """
  HTTP wrapper for HTTPoison library. Possible to extend functions for outgoing/ingoing headers,
  body, etc. at this place. https://github.com/edgurgel/httpoison, Wrapping HTTPoison.Base section
  """
  use Rig.Config, [:recv_timeout]
  use HTTPoison.Base

  defp process_request_options(options) do
    conf = config()
    Keyword.put(options, :recv_timeout, conf.recv_timeout)
  end
end
