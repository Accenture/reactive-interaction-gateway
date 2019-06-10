defmodule Client do
  @moduledoc false
  @type client :: pid | reference | atom
  @callback connect(params :: list) :: {:ok, pid}
  @callback disconnect(client) :: :ok
  @callback refute_receive(client) :: :ok
  @callback read_event(client, event_type :: String.t()) :: map()
  @callback read_welcome_event(client) :: map()
  @callback read_subscriptions_set_event(client) :: map()
end

defmodule TestClient.ConnectionError do
  defexception [:code, :mailbox]

  def exception(code, mailbox),
    do: %__MODULE__{code: code, mailbox: mailbox}

  def message(%__MODULE__{code: code, mailbox: mailbox}),
    do:
      "could not establish connection, server responded with #{inspect(code)}: #{inspect(mailbox)}"
end

defmodule SseClient do
  @moduledoc false
  @behaviour Client
  alias Jason

  defdelegate url_encode_subscriptions(list), to: Jason, as: :encode!

  @impl true
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

    url = "http://#{hostname}:#{eventhub_port}/_rig/v1/connection/sse?#{URI.encode_query(params)}"

    %HTTPoison.AsyncResponse{id: client} =
      HTTPoison.get!(url, %{accept: "text/event-stream"},
        stream_to: self(),
        recv_timeout: 20_000
      )

    receive do
      %HTTPoison.AsyncStatus{code: 200} ->
        :ok

      %HTTPoison.AsyncStatus{code: code} ->
        raise TestClient.ConnectionError, code: code, mailbox: flush_mailbox()
    after
      500 -> raise "No response"
    end

    receive do
      %HTTPoison.AsyncHeaders{} -> :ok
    after
      500 -> raise "No response"
    end

    {:ok, client}
  end

  @impl true
  def disconnect(client) do
    {:ok, ^client} = :hackney.stop_async(client)
    :ok
  end

  @impl true
  def refute_receive(_client) do
    receive do
      %HTTPoison.AsyncChunk{} = async_chunk ->
        raise "Unexpectedly received: #{inspect(async_chunk)}"
    after
      100 -> :ok
    end
  end

  @impl true
  def read_event(_client, event_type) do
    cloud_event =
      read_sse_chunk()
      |> extract_cloud_event()

    case cloud_event do
      %{"specversion" => "0.2", "type" => ^event_type} -> cloud_event
      %{"cloudEventsVersion" => "0.1", "eventType" => ^event_type} -> cloud_event
    end
  end

  @impl true
  def read_welcome_event(client), do: read_event(client, "rig.connection.create")

  @impl true
  def read_subscriptions_set_event(client), do: read_event(client, "rig.subscriptions_set")

  defp read_sse_chunk do
    receive do
      %HTTPoison.AsyncChunk{chunk: chunk} -> chunk
    after
      1_000 ->
        raise "No chunk to read after 1s. #{inspect(:erlang.process_info(self(), :messages))}"
    end
  end

  defp extract_cloud_event(sse_chunk) do
    data =
      sse_chunk
      |> String.split("\n")
      |> Enum.drop_while(&(not String.starts_with?(&1, "data: ")))
      |> Enum.take_while(&String.starts_with?(&1, "data: "))
      |> Enum.map(fn "data: " <> data -> data end)
      |> Enum.join("\n")

    case Jason.decode(data) do
      {:ok, cloud_event} -> cloud_event
      {:error, _} -> raise "Got non-JSON data: #{inspect(data)}"
    end
  end

  defp flush_mailbox do
    receive do
      msg -> [msg | flush_mailbox()]
    after
      100 -> []
    end
  end
end

defmodule WsClient do
  @moduledoc false
  @behaviour Client
  alias Jason
  alias Socket.Web, as: WebSocket

  defdelegate url_encode_subscriptions(list), to: Jason, as: :encode!

  @impl true
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

    WebSocket.connect(hostname, eventhub_port, %{
      path: "/_rig/v1/connection/ws?#{URI.encode_query(params)}",
      protocol: ["ws"]
    })
  end

  @impl true
  def disconnect(client) do
    :ok = WebSocket.close(client)
  end

  @impl true
  def refute_receive(client) do
    case WebSocket.recv(client, timeout: 100) do
      {:ping, _} -> client.refute_receive(client)
      {:ok, packet} -> raise "Unexpectedly received: #{inspect(packet)}"
      {:error, _} -> :ok
    end
  end

  @impl true
  def read_event(client, event_type) do
    {:text, data} = WebSocket.recv!(client)
    cloud_event = Jason.decode!(data)

    case cloud_event do
      %{"specversion" => "0.2", "type" => ^event_type} -> cloud_event
      %{"cloudEventsVersion" => "0.1", "eventType" => ^event_type} -> cloud_event
    end
  end

  @impl true
  def read_welcome_event(client), do: read_event(client, "rig.connection.create")

  @impl true
  def read_subscriptions_set_event(client), do: read_event(client, "rig.subscriptions_set")
end
