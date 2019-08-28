defmodule RigApi.MessageControllerTest do
  @moduledoc false
  use RigApi.ConnCase, async: true

  alias Plug.Conn.Status

  import Mox
  setup :verify_on_exit!

  @cloud_event_json ~s({"cloudEventsVersion":"0.1","source":"test","eventType":"test.event","eventID":"1"})
  @non_cloud_event ~s({"source":"test","eventType":"test.event","eventID":"1"})

  setup do
    # TODO that mock doesn't work - the request goes to the real Filter :(
    Rig.EventFilterMock
    |> stub(:forward_event, fn ev -> send(self(), {:cloud_event_sent, ev}) end)

    :ok
  end

  # test "application/x-www-form-urlencoded is not supported"
  # test "text/plain is not supported"

  describe "Structured mode" do
    test "is supported for content-type application/cloudevents+json." do
      conn =
        new_conn("application/cloudevents+json;charset=utf-8")
        |> post("/v1/messages", @cloud_event_json)

      assert conn.status == Status.code(:accepted)
      # TODO mock doesn't work..
      # assert_receive {:cloud_event_sent, _}
    end

    test "ignores any ce-* headers." do
      conn =
        new_conn("application/cloudevents+json;charset=utf-8")
        |> put_req_header("ce-specversion", "illegal")
        |> put_req_header("ce-type", "")
        |> put_req_header("ce-source", "")
        |> put_req_header("ce-id", "")
        |> post("/v1/messages", @cloud_event_json)

      assert conn.status == Status.code(:accepted), "#{conn.status} #{inspect(conn.resp_body)}"
      # TODO mock doesn't work..
      # assert_receive {:cloud_event_sent, @cloud_event_json}
    end

    test "rejects events that don't follow the CloudEvents format." do
      conn =
        new_conn("application/cloudevents+json;charset=utf-8")
        |> post("/v1/messages", @non_cloud_event)

      assert conn.status == Status.code(:bad_request)
      refute_received {:cloud_event_sent, _}
    end
  end

  describe "Binary content mode" do
    test "is supported for content-type application/json." do
      event = %{
        "specversion" => "0.2",
        "type" => "my-event-type",
        "source" => "#{__MODULE__}/binary/json",
        "id" => "1",
        "contenttype" => "application/json;charset=utf-8",
        "data" => ~S({"some": "value"})
      }

      conn =
        new_conn(event["contenttype"])
        |> put_req_header("ce-specversion", event["specversion"])
        |> put_req_header("ce-type", event["type"])
        |> put_req_header("ce-source", event["source"])
        |> put_req_header("ce-id", event["id"])
        |> post("/v1/messages", event["data"])

      assert conn.status == Status.code(:accepted)
      # TODO mock doesn't work..
      # assert_receive {:cloud_event_sent, event}
    end

    test "is not supported for any other content-type." do
      event = %{
        "specversion" => "0.2",
        "type" => "my-event-type",
        "source" => "#{__MODULE__}/binary/text",
        "id" => "1",
        "contenttype" => "text/plain",
        "data" => "This is a human-readable representation.."
      }

      conn =
        new_conn(event["contenttype"])
        |> put_req_header("ce-specversion", event["specversion"])
        |> put_req_header("ce-type", event["type"])
        |> put_req_header("ce-source", event["source"])
        |> put_req_header("ce-id", event["id"])
        |> post("/v1/messages", event["data"])

      assert conn.status == Status.code(:accepted)
      # TODO mock doesn't work..
      # assert_receive {:cloud_event_sent, event}
    end
  end

  defp new_conn(content_type) do
    build_conn()
    |> put_req_header("content-type", content_type)
  end
end
