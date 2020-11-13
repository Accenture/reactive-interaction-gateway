defmodule RigInboundGatewayWeb.Net do
  @moduledoc false

  def tcp_port_free?(port_num) do
    import Enum

    :erlang.ports()
    |> map(fn port ->
      info =
        case :erlang.port_info(port) do
          info when is_list(info) -> info
          _ -> []
        end

      {port, info}
    end)
    |> filter(fn {_port, info} -> info[:name] == 'tcp_inet' end)
    |> reduce_while(nil, fn {port, info}, _acc ->
      case :inet.port(port) do
        {:ok, ^port_num} -> {:halt, info[:connected]}
        _ -> {:cont, nil}
      end
    end)
    |> case do
      nil ->
        true

      _pid ->
        # Process.exit(pid, :kill)
        false
    end
  end
end
