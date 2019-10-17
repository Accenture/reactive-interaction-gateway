defmodule RigInboundGatewayWeb.Cors do
  @moduledoc false

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def cors do
    quote do
      defp with_allow_origin(conn) do
        %{cors: origins} = config()
        put_resp_header(conn, "access-control-allow-origin", origins)
      end
    end
  end

  def preflight_put do
    quote do
      @doc false
      def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
        conn
        |> with_allow_origin()
        |> put_resp_header("access-control-allow-methods", "PUT")
        |> put_resp_header("access-control-allow-headers", "content-type,authorization")
        |> send_resp(:no_content, "")
      end
    end
  end

  def preflight_all do
    quote do
      @doc false
      def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
        conn
        |> with_allow_origin()
        |> put_resp_header("access-control-allow-methods", "*")
        |> put_resp_header("access-control-allow-headers", "content-type,authorization")
        |> send_resp(:no_content, "")
      end
    end
  end
end
