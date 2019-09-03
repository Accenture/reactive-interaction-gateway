defmodule Probe do
  @moduledoc false
  require Logger

  def wait_for_endpoint(enabled?, port, n_remaining_attempts \\ 20)

  def wait_for_endpoint(false, _, _), do: :ok

  def wait_for_endpoint(true, _, 0),
    do: raise("Got tired of waiting for the endpoint to come up :(")

  def wait_for_endpoint(true, port, n_remaining_attempts) do
    Logger.debug("checking whether endpoint is up...")

    case HTTPoison.get("http://localhost:#{port}/_rig/health") do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.debug("endpoint is up")

      {:ok, %HTTPoison.Response{} = res} ->
        raise "Unexpected response: #{inspect(res)}"

      {:error, _} ->
        # This rarely happens as usually the initial request simply blocks until the
        # endpoint is available.
        Logger.debug("endpoint is not up yet, waiting..")
        :timer.sleep(100)
        wait_for_endpoint(true, port, n_remaining_attempts - 1)
    end
  end
end

{:ok, _} = Application.ensure_all_started(:fake_server)

# Wait for endpoints to come up.
#
# # Why this is needed
#
# While Rancher is pretty quick to set up the TCP sockets that receive the web traffic,
# Phoenix needs a bit more time to set up its endpoints. This means that for a small
# amount of time after starting up RIG, the ports are open but the endpoints are not
# reachable. This causes integration tests to fail, as they rely on those endpoints.
#
# The clean way to solve this would be to make sure that the endpoints are present in
# these integration tests. However, currently the integration tests don't share a common
# setup. To keep the effort down, we're waiting on the endpoint here, before running
# _any_ test. In case the integration tests are put into a dedicated test suite at some
# point in the future, this check should be moved to the suit's setup routine.
endpoint_enabled? = Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:server]
port = Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
Probe.wait_for_endpoint(endpoint_enabled?, port)

ExUnit.start()
# Exclude all smoke tests from running by default
ExUnit.configure(exclude: [smoke: true, kafka: true, kinesis: true, avro: true, skip: true])
