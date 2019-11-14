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
        Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
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

    %{status_code: 200, headers: headers} = HTTPoison.get!(url)

    cookies =
      for({"set-cookie", val} <- headers, do: val)
      |> Enum.join("; ")

    {:ok, cookies}
  end

  def read_events(cookies) do
    hostname = "localhost"

    eventhub_port = Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

    url = "http://#{hostname}:#{eventhub_port}/_rig/v1/connection/longpolling"

    %{status_code: 200, headers: headers, body: body} =
      HTTPoison.get!(url, %{}, hackney: [cookie: cookies], recv_timeout: 60_000)

    cookies =
      for({"set-cookie", val} <- headers, do: val)
      |> Enum.join("; ")

    %{"events" => events} = Jason.decode!(body)
    {:ok, events, cookies}
  end
end
