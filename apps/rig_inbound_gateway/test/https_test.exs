defmodule RigInboundGateway.HttpsTest do
  @moduledoc """
  A simple test that ensures the HTTPS endpoint is up and running.
  """
  use ExUnit.Case, async: true

  alias HTTPoison
  alias Jason

  @event_hub_https_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[
                          :https
                        ][:port]

  test "The SSE endpoint supports HTTPS." do
    url = "https://localhost:#{@event_hub_https_port}/_rig/v1/connection/sse"

    %HTTPoison.AsyncResponse{id: conn_ref} =
      HTTPoison.get!(url, %{}, stream_to: self(), ssl: [verify: :verify_none])

    assert_receive %HTTPoison.AsyncStatus{code: 200, id: ^conn_ref}
  end
end
