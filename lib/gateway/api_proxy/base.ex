defmodule Gateway.ApiProxy.Base do
  @moduledoc """
  Provides forwarding of REST requests to external services.
  """
  use HTTPoison.Base

  @spec process_headers(map) :: list(tuple)
  def process_headers(headers) do
    # Remove transfer Encoding from headers since it collides with
    # Content-length and leads to error request
    headers
    |> List.keydelete("Transfer-Encoding", 0)
  end
end
