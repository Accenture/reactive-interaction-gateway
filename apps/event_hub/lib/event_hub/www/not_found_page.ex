defmodule EventHub.WWW.NotFoundPage do
  use Raxx.Server
  use EventHub.WWW.HTMLView

  @impl Raxx.Server
  def handle_request(_request, _state) do
    response(:not_found)
    |> render(%{})
  end
end
