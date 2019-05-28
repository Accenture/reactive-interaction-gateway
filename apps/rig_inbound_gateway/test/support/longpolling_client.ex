defmodule LongpollingClient do
  @moduledoc false
  alias Jason

  defdelegate url_encode_subscriptions(list), to: Jason, as: :encode!

  def connect(params \\ []) do
    {hostname, params} = Keyword.pop(params, :hostname, "localhost")

    {eventhub_port, params} =
      Keyword.pop(
        params,
        :port,
        Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][:port]
      )

    params =
      if Keyword.has_key?(params, :subscriptions) do
        encoded_subscriptions = params[:subscriptions] |> url_encode_subscriptions()
        Keyword.replace!(params, :subscriptions, encoded_subscriptions)
      else
        params
      end

    url =
      "http://#{hostname}:#{eventhub_port}/_rig/v1/connection/longpolling?#{
        URI.encode_query(params)
      }"

    response = HTTPoison.get!(url)

    cookies =
      for({"set-cookie", val} <- response.headers, do: val)
      |> Enum.join("; ")

    {:ok, cookies}
  end

  def read_events(cookies) do
    hostname = "localhost"

    eventhub_port =
      Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][:port]

    url = "http://#{hostname}:#{eventhub_port}/_rig/v1/connection/longpolling"

    response = HTTPoison.get!(url, %{}, hackney: [cookie: cookies], recv_timeout: 60_000)

    cookies =
      for({"set-cookie", val} <- response.headers, do: val)
      |> Enum.join("; ")

    response_body = response.body |> Jason.decode!()
    events = response_body["events"]

    {:ok, events, cookies}
  end
end
