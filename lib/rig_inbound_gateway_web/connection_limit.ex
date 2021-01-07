defmodule RigInboundGatewayWeb.ConnectionLimit do
  @moduledoc "Used to enforce a limit on the maximum connections per minute"

  defmodule MaxConnectionsError do
    defexception [:n_connections]

    def message(%__MODULE__{}),
      do: "Reached maximum number of connections"
  end

  use Rig.Config, [:max_connections_per_minute, :max_connections_per_minute_bucket]

  @minute 60_000

  # ---

  @spec check_rate_limit() :: {:ok, integer} | {:error, %MaxConnectionsError{}}
  def check_rate_limit do
    {:ok, n_connections} =
      ExRated.check_rate(
        config().max_connections_per_minute_bucket,
        @minute,
        config().max_connections_per_minute
      )

    {:ok, n_connections}
  catch
    :error, {:badmatch, {:error, n_connections}} ->
      {:error, %MaxConnectionsError{n_connections: n_connections}}
  end
end
