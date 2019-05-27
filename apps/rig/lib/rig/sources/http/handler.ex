defmodule RIG.Sources.HTTP.Handler do
  @moduledoc """
  Common request handler for HTTP endpoints that accept CloudEvents.

  The handler implements [HTTP Transport Binding for CloudEvents - Version 0.2](https://github.com/cloudevents/spec/blob/v0.2/http-transport-binding.md).
  """

  import Phoenix.Controller, only: [text: 2, json: 2]
  import Plug.Conn, only: [put_status: 2]

  alias Jason
  alias Plug.Conn

  alias Rig.EventFilter
  alias RIG.Plug.BodyReader
  alias RigAuth.AuthorizationCheck.Submission
  alias RigCloudEvents.CloudEvent
  alias RigCloudEvents.PlugUtils
  alias RigInboundGatewayWeb.MediaTypeHandling

  def handle_http_submission(conn, opts \\ []) do
    {check_authorization?, _opts} = Keyword.pop(opts, :check_authorization?, true)

    conn
    |> Conn.assign(:check_authorization?, check_authorization?)
    |> PlugUtils.handle_cloudevent(
      binary: &handle_binary_mode/1,
      structured: &handle_structured_mode/1
    )
  end

  # ---

  # The spec about binary mode:
  #
  # > The binary content mode accommodates any shape of event data, and allows for
  # > efficient transfer and without transcoding effort. The HTTP Content-Type value
  # > maps directly to the CloudEvents datacontenttype attribute. The context attributes
  # > are sent in the header.
  #
  # Well not so efficient in our case, since we have to transcode everything anyway..
  defp handle_binary_mode(conn) do
    with ["0.2"] <- Conn.get_req_header(conn, "ce-specversion") do
      {conn, json} = build_cloudevent_json(conn)

      json
      |> CloudEvent.parse()
      |> case do
        {:ok, cloud_event} ->
          handle_event(conn, cloud_event)

        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> text("""
          Your request looks like it's using the CloudEvents binary content mode \
          but can't be parsed (#{inspect(reason)}). Please make sure you're \
          passing the headers according to the spec:

          HTTP Transport Binding for CloudEvents
          https://github.com/cloudevents/spec/blob/master/http-transport-binding.md

          Request headers:
          #{for {k, v} <- conn.req_headers, into: "", do: "  #{k}: #{v}\n"}
          """)
      end
    else
      ce_specversion_headers ->
        conn
        |> put_status(:bad_request)
        |> text("""
        Your request looks like it's using the CloudEvents binary content mode, \
        but the ce-specversion header is #{inspect(ce_specversion_headers)} \
        instead of [\"0.2\"].\
        """)
    end
  end

  # ---

  defp build_cloudevent_json(conn) do
    context_attributes = context_attributes_from_headers(conn.req_headers)
    {:ok, body, conn} = BodyReader.read_full_body(conn)

    event =
      case MediaTypeHandling.media_type(context_attributes["contenttype"]) do
        {"application", "json"} ->
          # Decoding the body allows to use fields in `data` in subscriptions:
          context_attributes
          |> Map.put("data", Jason.decode!(body))
          |> Map.delete("contenttype")

        _ ->
          context_attributes
          |> Map.put("data", body)
      end

    {conn, Jason.encode!(event)}
  end

  # ---

  @ce_standard_headers [
    "specversion",
    "type",
    "source",
    "id",
    "time",
    "schemaurl"
  ]
  defp context_attributes_from_headers(headers) do
    [content_type] = for {"content-type", val} <- headers, do: val

    for {"ce-" <> attr, val} <- headers, into: %{} do
      case attr do
        attr when attr in @ce_standard_headers ->
          {attr, val}

        _ ->
          # If this is a CloudEvents extension field, it might be JSON encoded:
          case Jason.decode(val) do
            {:ok, val} -> {attr, val}
            _ -> {attr, val}
          end
      end
    end
    |> Map.put("contenttype", content_type)
  end

  # ---

  # The spec about structured mode:
  #
  # > The structured content mode keeps event metadata and data together in the payload,
  # > allowing simple forwarding of the same event across multiple routing hops, and
  # > across multiple transports.
  defp handle_structured_mode(conn) do
    content_type = MediaTypeHandling.content_type(conn)

    json? =
      case content_type do
        {"application", "json"} -> true
        {"application", "cloudevents+json"} -> true
        _ -> false
      end

    if json? do
      with {:ok, json, conn} <- BodyReader.read_full_body(conn),
           {:ok, cloud_event} <- CloudEvent.parse(json) do
        handle_event(conn, cloud_event)
      else
        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> text("The request body does not look like a CloudEvent: #{inspect(reason)}")
      end
    else
      conn
      |> put_status(:unsupported_media_type)
      |> text(
        "The given content-type #{inspect(content_type)} is currently not supported for structured mode."
      )
    end
  end

  # ---

  defp handle_event(conn, %CloudEvent{} = cloud_event) do
    authorized? =
      if conn.assigns[:check_authorization?] do
        Submission.check_authorization(conn, cloud_event) == :ok
      else
        true
      end

    if authorized? do
      :ok = EventFilter.forward_event(cloud_event)

      conn
      |> put_status(:accepted)
      |> json(cloud_event.json)
    else
      conn
      |> put_status(:forbidden)
      |> text("Submission denied.")
    end
  end
end
