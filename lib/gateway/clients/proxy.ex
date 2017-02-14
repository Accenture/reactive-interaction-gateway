defmodule Gateway.Clients.Proxy do
  @moduledoc """
  Provides forwarding of REST requests to external services.
  """
  use HTTPoison.Base

  def process_headers(_headers) do
    [{"Content-Type", "application/json; charset=utf-8"}, {"Content-Encoding", "gzip"}]
  end
end
