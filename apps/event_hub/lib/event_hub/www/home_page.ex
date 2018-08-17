defmodule EventHub.WWW.HomePage do
  use Raxx.Server
  use EventHub.WWW.HTMLView

  @impl Raxx.Server
  def handle_request(_request, _state) do
    response(:ok)
    |> render(%{})
  end
end
