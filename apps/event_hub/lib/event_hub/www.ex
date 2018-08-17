defmodule EventHub.WWW do
  use Ace.HTTP.Service, port: 8080, cleartext: true

  @external_resource "lib/event_hub/www.apib"
  use Raxx.ApiBlueprint, "./www.apib"

  @external_resource "lib/event_hub/public/main.css"
  @external_resource "lib/event_hub/public/main.js"
  use Raxx.Static, "./public"
  use Raxx.Logger, level: :info

  # Fallback:
  def handle_head(_request, _state) do
    Raxx.response(:not_found)
    |> Raxx.set_body("Not found.")
  end
end
