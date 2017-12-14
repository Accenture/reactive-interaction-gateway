defmodule RigInboundGateway.ApiProxy.Base do
  @moduledoc """
  HTTP wrapper for HTTPoison library. Possible to extend functions for outgoing/ingoing headers,
  body, etc. at this place. https://github.com/edgurgel/httpoison, Wrapping HTTPoison.Base section
  """
  use HTTPoison.Base
end
