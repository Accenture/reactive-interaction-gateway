defmodule RigInboundGateway.EventSubmission.JwtCheckTest do
  @moduledoc """
  The jwt_validation setting requires a valid JWT to publish events.
  """
  # Cannot be async because environment variables are modified:
  use ExUnit.Case, async: false

  alias HTTPoison

  alias RIG.JWT

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
    System.put_env(@var_name, "jwt_validation")

    on_exit(fn ->
      case @orig_val do
        nil -> System.delete_env(@var_name)
        _ -> System.put_env(@var_name, @orig_val)
      end
    end)
  end

  test "Both APIs allow publishing an event when using a valid JWT." do
    valid_jwt = JWT.encode(%{})

    headers = %{
      "content-type" => "application/json",
      "authorization" => "Bearer #{valid_jwt}"
    }

    assert %{status_code: 202} = HTTPoison.post!(@public_submission_url, @event_json, headers)
    assert %{status_code: 202} = HTTPoison.post!(@private_submission_url, @event_json, headers)
  end

  test "The inbound API denies publishing an event if there is no JWT present, but the outbound one doesn't care." do
    headers = %{"content-type" => "application/json"}
    assert %{status_code: 403} = HTTPoison.post!(@public_submission_url, @event_json, headers)
    assert %{status_code: 202} = HTTPoison.post!(@private_submission_url, @event_json, headers)
  end

  test "The inbound API deny publishing an event if the given JWT cannot be validated, but the outbound one doesn't care." do
    invalid_jwt = "definitely not a valid jwt"

    headers = %{
      "content-type" => "application/json",
      "authorization" => "Bearer #{invalid_jwt}"
    }

    assert %{status_code: 403} = HTTPoison.post!(@public_submission_url, @event_json, headers)
    assert %{status_code: 202} = HTTPoison.post!(@private_submission_url, @event_json, headers)
  end
end
