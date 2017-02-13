defmodule Gateway.Clients.Proxy do
  use HTTPoison.Base
    
  def process_headers(headers) do
    [{"Content-Type", "application/json; charset=utf-8"}, {"Content-Encoding", "gzip"}]
  end
end