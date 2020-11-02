defmodule RIG.AuthorizationCheck.Request do
  @moduledoc false

  defmodule AuthInfo do
    @moduledoc false
    use TypedStruct

    @type auth_token :: {schema :: String.t(), value :: String.t()}

    @typedoc "Authorization tokens."
    typedstruct do
      field(:auth_header, String.t(), enforce: true)
      field(:auth_tokens, [auth_token], enforce: true)
    end
  end

  use TypedStruct

  alias Plug.Conn

  @typedoc "Subscription or submission request."
  typedstruct do
    field(:auth_info, AuthInfo.t())
    field(:query_params, map(), default: %{})
    field(:content_type, String.t(), enforce: true)
    field(:body, String.t(), default: "")
  end

  # ---

  @spec from_plug_conn(Conn.t()) :: __MODULE__.t()
  def from_plug_conn(conn)

  def from_plug_conn(%{query_params: %Plug.Conn.Unfetched{}}),
    do: :ok = :bug__query_params_unfetched

  def from_plug_conn(conn) do
    [content_type] = Conn.get_req_header(conn, "content-type")

    %{
      auth_info: auth_info(conn),
      query_params: conn.query_params,
      content_type: content_type,
      body: conn.assigns[:body] || ""
    }
  end

  # ---

  defp auth_info(conn)

  defp auth_info(%{assigns: %{auth_tokens: tokens}} = conn) do
    auth_header = for({"authorization", val} <- conn.req_headers, do: val) |> Enum.join(", ")

    %{
      auth_header: auth_header,
      auth_tokens: tokens
    }
  end

  defp auth_info(_), do: nil
end
