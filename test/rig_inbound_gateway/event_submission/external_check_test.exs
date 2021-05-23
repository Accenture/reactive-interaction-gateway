defmodule RigInboundGateway.EventSubmission.ExternalCheckTest do
  @moduledoc """
  An external service may be used to allow or deny publishing events.
  """
  # Cannot be async because environment variables are modified:
  use ExUnit.Case, async: false

  import FakeServer
  alias FakeServer.Response

  alias HTTPoison

  alias RIG.JWT

  @hostname "localhost"
  @eventhub_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]
  @public_submission_url "http://#{@hostname}:#{@eventhub_port}/_rig/v1/events"
  @private_submission_url "http://#{@hostname}:#{@api_port}/v3/messages"
  @fake_validation_service_port 59_349

  @event_json """
  { "id": "2", "source": "nil", "specversion": "0.2", "type": "greeting" }
  """

  @var_name "SUBMISSION_CHECK"
  @orig_val System.get_env(@var_name)
  setup_all do
    System.put_env(@var_name, "http://localhost:#{@fake_validation_service_port}")

    on_exit(fn ->
      case @orig_val do
        nil -> System.delete_env(@var_name)
        _ -> System.put_env(@var_name, @orig_val)
      end
    end)
  end

  test "The private API doesn't use the external service." do
    headers = %{"content-type" => "application/json"}
    assert %{status_code: 202} = HTTPoison.post!(@private_submission_url, @event_json, headers)
  end

  test_with_server "The public API allows publishing if the external service accepts.",
    port: @fake_validation_service_port do
    # The fake subscription-validation service accepts anything:
    route("/", Response.ok!("Ok"))

    headers = %{"content-type" => "application/json"}
    assert %{status_code: 202} = HTTPoison.post!(@public_submission_url, @event_json, headers)
  end

  test_with_server "The public API denies publishing if the external service rejects.",
    port: @fake_validation_service_port do
    # The fake subscription-validation service rejects anything:
    route("/", Response.forbidden!("Go away!"))

    headers = %{"content-type" => "application/json"}
    assert %{status_code: 403} = HTTPoison.post!(@public_submission_url, @event_json, headers)
  end
end
