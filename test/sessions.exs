defmodule RigTests.SessionsTest do
  @moduledoc """
  Make sure sessions can be listed and killed off using RIG's API.

  """
  use ExUnit.Case, async: false

  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]

  describe "With the legacy API," do
    test "GET /v1/users returns the list of users." do
      # TODO
    end

    test "GET /v1/users/{user_id}/sessions returns a list of devices a user is connected with." do
      # TODO
    end

    # With RIG 1.x this would only disconnect a single device by referring to the JWT's
    # jti, which was unique for each device.
    test "DELETE /v1/sessions/{session_id} blacklists a single token (not the session) and disconnects the related device." do
      # TODO
    end
  end

  describe "The new semantics" do
    test "are defined later.." do
      # TODO
    end
  end
end
