defmodule RigApi.V2.SessionBlacklist do
  @moduledoc """
  Controller that allows blocking "sessions" for a specific period of time.

  What a session is depends on your business context and the `JWT_SESSION_FIELD`
  setting. For example, a session ID could be a random ID assigned to a token upon
  login, or the id of the user the token belongs to.
  """
  use RigApi, :controller
  use PhoenixSwagger
  require Logger

  alias RIG.Session

  @prefix "/v2"
  @cors_origins "*"

  # ---

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_resp(:no_content, "")
  end

  # ---

  defp with_allow_origin(conn) do
    put_resp_header(conn, "access-control-allow-origin", @cors_origins)
  end

  # ---

  swagger_path :check_status do
    get(@prefix <> "/session-blacklist/{sessionId}")
    summary("Check whether a given session is currently blacklisted.")

    parameters do
      sessionId(:path, :string, "The JWT ID (jti) claim that identifies the session.",
        required: true
      )
    end

    response(200, "This session is currently blacklisted.")
    response(404, "There is no entry in the blacklist that matches this session name.")
  end

  @doc "Check blacklist status for a specific session id."
  def check_status(%{method: "GET"} = conn, %{"session_id" => session_id}) do
    if Session.blacklisted?(session_id) do
      conn
      |> put_resp_header("content-type", "application/json; charset=utf-8")
      |> send_resp(:ok, "{}")
    else
      conn
      |> send_resp(:not_found, "Not found.")
    end
  end

  # ---

  swagger_path :blacklist_session do
    post(@prefix <> "/session-blacklist")
    summary("Add a session to the session blacklist.")

    description("""
    When successful, the given session is no longer considered valid, regardless of \
    the token's expiration timestamp. This has the following consequences:

    - Any existing connection related to the session is terminated immediately.
    - The related authorization token is no longer valid when a client establishes a connection.
    - The related authorization token is no longer valid when a client creates a subscription.
    """)

    parameters do
      sessionBlacklist(
        :body,
        Schema.ref(:SessionBlacklistRequest),
        "The details for blacklisting a session",
        required: true
      )
    end

    response(
      201,
      "The session is now blacklisted. The location header points to the newly created entry."
    )

    response(400, "Bad request.")
  end

  @doc "Plug action to add a session id to the session blacklist."
  def blacklist_session(%{method: "POST"} = conn, _params) do
    conn = with_allow_origin(conn)

    case parse(conn.body_params) do
      {:error, reason} ->
        send_resp(conn, :bad_request, reason)

      {:ok, %{session_id: session_id, ttl_s: ttl_s}} ->
        Session.blacklist(session_id, ttl_s)

        location = Path.join(conn.request_path, "/#{session_id}")

        conn
        |> put_resp_header("location", location)
        |> put_resp_header("content-type", "application/json; charset=utf-8")
        |> send_resp(:created, "{}")
    end
  end

  # ---

  defp parse(body) do
    Result.ok(%{})
    |> Result.and_then(&parse_and_add_session_id(&1, body))
    |> Result.and_then(&parse_and_add_ttl_s(&1, body))
  end

  # ---

  defp parse_and_add_session_id(into, from) do
    case Map.fetch(from, "sessionId") do
      {:ok, value} when byte_size(value) > 0 -> {:ok, Map.merge(into, %{session_id: value})}
      {:ok, value} -> {:error, "Expected non-empty string, got #{inspect(value)}"}
      :error -> {:error, "Missing value for \"sessionId\""}
    end
  end

  # ---

  defp parse_and_add_ttl_s(into, from) do
    case Map.fetch(from, "validityInSeconds") do
      {:ok, value} when is_number(value) and value > 0 ->
        {:ok, Map.merge(into, %{ttl_s: value})}

      {:ok, value} when byte_size(value) > 0 ->
        case Integer.parse(value) do
          {value, ""} -> parse_and_add_ttl_s(into, Map.put(from, "validityInSeconds", value))
          _ -> {:error, "Expected a number, got #{inspect(value)}"}
        end

      {:ok, value} ->
        {:error, "Expected a positive number, got #{inspect(value)}"}

      :error ->
        {:error, "Missing value for \"validityInSeconds\""}
    end
  end

  # ---

  def swagger_definitions do
    %{
      SessionBlacklistRequest:
        swagger_schema do
          title("Session Blacklist Request")

          properties do
            sessionId(
              :string,
              """
              The JWT claim that defines a "session". For details see the \
              `JWT_SESSION_FIELD` setting in the operator's guide \
              (https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html).
              """,
              required: true
            )

            validityInSeconds(
              :number,
              """
              Defines how long the sessionId will stay on the blacklist. \
              Typically set to the JWT's remaining lifetime.
              """,
              required: true
            )
          end

          example(%{
            sessionId: "SomeSessionID123",
            validityInSeconds: 60
          })
        end
    }
  end
end
