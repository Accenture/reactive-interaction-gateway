defmodule RigInboundGateway.EventSubmission.NoCheckTest do
  @moduledoc """
  The no_check setting lets anyone publish events.
  """
  # Cannot be async because environment variables are modified:
  use ExUnit.Case, async: false

  alias HTTPoison

  @hostname "localhost"
  @eventhub_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]
  @public_submission_url "http://#{@hostname}:#{@eventhub_port}/_rig/v1/events"
  @private_submission_url "http://#{@hostname}:#{@api_port}/v3/messages"

  @event_json """
  { "id": "2", "source": "nil", "specversion": "0.2", "type": "greeting" }
  """

  @var_name "SUBMISSION_CHECK"
  @orig_val System.get_env(@var_name)
  setup_all do
    System.put_env(@var_name, "no_check")

    on_exit(fn ->
      case @orig_val do
        nil -> System.delete_env(@var_name)
        _ -> System.put_env(@var_name, @orig_val)
      end
    end)
  end

  test "Anyone can publish an event using any of the APIs" do
    headers = %{"content-type" => "application/json"}
    assert %{status_code: 202} = HTTPoison.post!(@public_submission_url, @event_json, headers)
    assert %{status_code: 202} = HTTPoison.post!(@private_submission_url, @event_json, headers)
  end
end
