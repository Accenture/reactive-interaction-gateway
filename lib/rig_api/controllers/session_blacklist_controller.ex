defmodule RigApi.SessionBlacklistController do
  @moduledoc """
  Allows for blocking "sessions" for a specific period of time.

  What a session is depends on your business context and the `JWT_SESSION_FIELD`
  setting. For example, a session ID could be a random ID assigned to a token upon
  login, or the id of the user the token belongs to.

  """
  use RigApi, :controller
  use PhoenixSwagger
  require Logger

  alias RIG.Session

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
    get("/v1/session-blacklist/{sessionId}")
    summary("Check whether a given session is currently blacklisted.")

    parameters do
      sessionId(:path, :string, "The JWT ID (jti) claim that identifies the session.",
        required: true
      )
    end

    response(200, "Ok", Schema.ref(:SessionBlacklistStatus))
  end

  @doc "Check blacklist status for a specific session id."
  def check_status(%{method: "GET"} = conn, %{"session_id" => session_id}) do
    json(conn, %{
      "sessionId" => session_id,
      "isBlacklisted" => Session.blacklisted?(session_id)
    })
  end

  # ---

  swagger_path :blacklist_session do
    post("/v1/session-blacklist")
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

    response(201, "Ok", Schema.ref(:SessionBlacklistResponse))
    response(400, "Missing value for 'x'")
  end

  @doc "Plug action to add a session id to the session blacklist."
  def blacklist_session(%{method: "POST"} = conn, _params) do
    conn = with_allow_origin(conn)

    case parse(conn.body_params) do
      {:error, reason} ->
        send_resp(conn, :bad_request, reason)

      {:ok, %{session_id: session_id, ttl_s: ttl_s}} ->
        Session.blacklist(session_id, ttl_s)

        send_resp(
          conn,
          :created,
          Jason.encode!(%{
            "sessionId" => session_id,
            "validityInSeconds" => ttl_s,
            "isBlacklisted" => true
          })
        )
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
          not_a_number -> {:error, "Expected a number, got #{inspect(not_a_number)}"}
        end

      {:ok, value} ->
        {:error, "Expected a number, got #{inspect(value)}"}

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
            sessionId(:string, "JWT ID (jti) claim", required: true)

            validityInSeconds(
              :number,
              "Defines how long the JWT ID should be considered invalid. Typically set to the token's remaining life time.",
              required: true
            )
          end

          example(%{
            sessionId: "SomeSessionID123",
            validityInSeconds: 60
          })
        end,
      SessionBlacklistResponse:
        swagger_schema do
          title("Session Blacklist Response")

          properties do
            sessionId(:string, "JWT ID (jti) claim", required: true)

            validityInSeconds(:number, "Seconds how long a session should be blacklisted",
              required: true
            )

            isBlacklisted(:boolean, "Current status of the blacklisted session", required: true)
          end

          example(%{
            sessionId: "SomeSessionID123",
            validityInSeconds: 60,
            isBlacklisted: true
          })
        end,
      SessionBlacklistStatus:
        swagger_schema do
          title("Session Blacklist Status")
          description("Status for a blacklisted session")

          properties do
            sessionId(:string, "JWT JTI session Id", required: true)
            isBlacklisted(:boolean, "Current status of the blacklisted session", required: true)
          end

          example(%{
            sessionId: "SomeSessionID123",
            isBlacklisted: true
          })
        end
    }
  end
end
