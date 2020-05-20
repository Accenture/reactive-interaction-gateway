defmodule RigInboundGateway.ApiProxy.Handler.HttpHeader do
  @moduledoc """
  HTTP header modification to be applied, according to the spec.
  """

  # ---

  @spec put_host_header(Plug.Conn.headers(), String.t()) :: Plug.Conn.headers()
  def put_host_header(req_headers, url) do
    %{host: host, port: port} = URI.parse(url)
    host_header = {"host", "#{host}:#{port}"}

    req_headers
    |> Enum.reject(fn {k, _} -> k === "host" end)
    |> Enum.concat([host_header])
  end

  # ---

  @type ip :: :inet.ip_address()
  @spec put_forward_header(Plug.Conn.headers(), remote_ip :: ip, host_ip :: ip) ::
          Plug.Conn.headers()
  def put_forward_header(req_headers, remote_ip, host_ip) do
    remote_ip = resolve_addr(remote_ip)
    host_ip = resolve_addr(host_ip)
    forward_header = {"forwarded", "for=#{remote_ip};by=#{host_ip}"}

    req_headers
    |> Enum.reject(fn {k, _} -> k === "forwarded" end)
    |> Enum.concat([forward_header])
  end

  # ---

  defp resolve_addr(ip_addr_or_hostname)

  defp resolve_addr(ip_addr) when is_tuple(ip_addr) do
    ip_addr |> :inet.ntoa() |> to_string()
  end

  defp resolve_addr(hostname) when byte_size(hostname) > 0 do
    {:ok, ip_addr} = hostname |> String.to_charlist() |> :inet.getaddr(:inet)
    resolve_addr(ip_addr)
  end
end
