defmodule RigApi.MessageControllerTest do
  @moduledoc false
  use RigApi.ConnCase
  use RigApi.ChannelCase

  alias Plug.Conn.Status

  @cloud_event_json ~s({"cloudEventsVersion":"0.1","source":"test","eventType":"test.event","eventID":"1"})
  @cloud_event_urlencoded "cloudEventsVersion=0.1&source=test&eventType=test.event&eventID=1"
  @non_cloud_event ~s({"source":"test","eventType":"test.event","eventID":"1"})
  @random_json_string ~s("some random string")

  defp new_conn(content_type) do
    build_conn()
    |> put_req_header("content-type", content_type)
  end

  describe "A Cloud Event v0.1 is" do
    test "accepted if content-type is application/json." do
      conn =
        new_conn("application/json;charset=utf-8")
        |> post("/v1/messages", @cloud_event_json)

      assert conn.status == Status.code(:accepted)
      assert_received {:cloud_event_sent, _}
    end

    test "accepted if content-type is application/x-www-form-urlencoded." do
      conn =
        new_conn("application/x-www-form-urlencoded;charset=utf-8")
        |> post("/v1/messages", @cloud_event_urlencoded)

      assert conn.status == Status.code(:accepted)
      assert_received {:cloud_event_sent, _}
    end

    test "denied for any other content-type." do
      conn = new_conn("text/plain")

      # Exception would be translated to conn.status == 415
      assert_raise Plug.Parsers.UnsupportedMediaTypeError,
                   "unsupported media type text/plain",
                   fn ->
                     post(conn, "/v1/messages", @cloud_event_json)
                   end

      refute_received {:cloud_event_sent, _}
    end
  end

  test "A JSON that is not a valid Cloud Event is not accepted." do
    conn =
      new_conn("application/json;charset=utf-8")
      |> post("/v1/messages", @non_cloud_event)

    assert conn.status == Status.code(:bad_request)
    refute_received {:cloud_event_sent, _}
  end

  test "A string is not accepted." do
    conn =
      new_conn("application/json;charset=utf-8")
      |> post("/v1/messages", @random_json_string)

    assert conn.status == Status.code(:bad_request)
    refute_received {:cloud_event_sent, _}
  end
end
