defmodule RigInboundGatewayWeb.Cors do
  @moduledoc false

  defmacro __using__(which) when is_list(which) do
    __MODULE__.cors_preflight(which)
  end

  defmacro __using__(_) do
    __MODULE__.cors_preflight([:*])
  end

  def cors_preflight(methods) do
    methods =
      methods
      |> Enum.map(&Atom.to_string/1)
      |> Enum.map(&String.upcase/1)
      |> Enum.join(",")

    quote do
      @doc false
      def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
        conn
        |> with_allow_origin()
        |> put_resp_header("access-control-allow-methods", unquote(methods))
        |> put_resp_header("access-control-allow-headers", "content-type,authorization")
        |> send_resp(:no_content, "")
      end

      @doc false
      defp with_allow_origin(conn) do
        %{cors: origins} = config()
        put_resp_header(conn, "access-control-allow-origin", origins)
      end
    end
  end
end
