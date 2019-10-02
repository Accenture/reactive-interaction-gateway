defmodule TestClient.ConnectionError do
  defexception [:code, :reason]

  def exception(code, reason),
    do: %__MODULE__{code: code, reason: reason}

  def message(%__MODULE__{code: code, reason: reason}),
    do:
      "could not establish connection, server responded with #{inspect(code)}: #{inspect(reason)}"
end

defmodule Client do
  @moduledoc false
  @type client :: pid | reference | atom | map
  @callback connect(params :: list) :: {:ok, pid}
  @callback disconnect(client) :: :ok
  @callback status(client) :: {:open, client} | {:closed, client}
  @callback refute_receive(client) :: :ok
  @callback read_event(client, event_type :: String.t()) :: map()
  @callback read_welcome_event(client) :: map()
  @callback read_subscriptions_set_event(client) :: map()
  @callback try_connect_then_disconnect(params :: list) ::
              {:ok, status :: any} | {:error, reason :: %TestClient.ConnectionError{}}
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
        Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
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
        raise TestClient.ConnectionError, code: code, reason: flush_mailbox()
    after
      500 -> raise "No response"
    end

    receive do
      %HTTPoison.AsyncHeaders{} -> :ok
    after
      500 -> raise "No response"
    end

    {:ok, %{client: client, status: :open}}
  end

  @impl true
  def disconnect(%{client: client, status: :open}) do
    {:ok, ^client} = :hackney.stop_async(client)
    :ok
  end

  @impl true
  def status(state)
  def status(%{status: :closed} = state), do: {:closed, state}

  def status(%{client: client} = state) do
    receive do
      %HTTPoison.AsyncEnd{id: ^client} -> {:closed, %{state | status: :closed}}
    after
      100 -> {:open, state}
    end
  end

  @impl true
  def refute_receive(%{status: :open} = state) do
    receive do
      %HTTPoison.AsyncChunk{} = async_chunk ->
        raise "Unexpectedly received: #{inspect(async_chunk)}"
    after
      100 -> {:ok, state}
    end
  end

  @impl true
  def read_event(%{status: :open} = state, event_type) do
    cloud_event =
      read_sse_chunk()
      |> extract_cloud_event()

    cloud_event =
      case cloud_event do
        %{"specversion" => "0.2", "type" => ^event_type} -> cloud_event
        %{"cloudEventsVersion" => "0.1", "eventType" => ^event_type} -> cloud_event
      end

    {cloud_event, state}
  end

  @impl true
  def read_welcome_event(state), do: read_event(state, "rig.connection.create")

  @impl true
  def read_subscriptions_set_event(state), do: read_event(state, "rig.subscriptions_set")

  @impl true
  def try_connect_then_disconnect(params \\ []) do
    {:ok, client} = connect(params)
    flush_mailbox()
    disconnect(client)
    {:ok, client}
  rescue
    err in [TestClient.ConnectionError] -> {:error, err}
  after
    flush_mailbox()
  end

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

  def flush_mailbox do
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
        Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
      )

    params =
      if Keyword.has_key?(params, :subscriptions) do
        encoded_subscriptions = params[:subscriptions] |> url_encode_subscriptions()
        Keyword.replace!(params, :subscriptions, encoded_subscriptions)
      else
        params
      end

    {:ok, client} =
      WebSocket.connect(hostname, eventhub_port, %{
        path: "/_rig/v1/connection/ws?#{URI.encode_query(params)}",
        protocol: ["ws"]
      })

    # We need to check whether the connection has already been closed:
    first_message =
      case WebSocket.recv(client, timeout: 100) do
        {:ok, {:close, code, reason}} ->
          raise TestClient.ConnectionError, code: code, reason: reason

        {:ok, message} ->
          message
      end

    {:ok, %{client: client, first_message: first_message, status: :open}}
  end

  @impl true
  def disconnect(%{client: client, status: :open}) do
    :ok = WebSocket.close(client)
  end

  @impl true
  def status(state)
  def status(%{status: :closed} = state), do: {:closed, state}

  def status(%{client: client} = state) do
    # No idea why, but the first ping is always successful, regardless of whether the
    # connection is still alive. As a workaround, we simply invoke ping twice.
    case WebSocket.ping(client) do
      {:error, _} ->
        {:closed, %{state | status: :closed}}

      _app_data ->
        # The second ping is successful too when done right after the first one.. O_o
        :timer.sleep(100)

        case WebSocket.ping(client) do
          {:error, _} -> {:closed, %{state | status: :closed}}
          _app_data -> {:open, state}
        end
    end
  end

  @impl true
  def refute_receive(%{client: client, first_message: first_message, status: :open} = state) do
    case first_message || WebSocket.recv(client, timeout: 100) do
      {:ping, _} -> client.refute_receive(client)
      {:ok, packet} -> raise "Unexpectedly received: #{inspect(packet)}"
      {:error, _} -> {:ok, %{state | first_message: nil}}
    end
  end

  @impl true
  def read_event(
        %{client: client, first_message: first_message, status: :open} = state,
        event_type
      ) do
    {:text, data} = first_message || WebSocket.recv!(client)

    cloud_event =
      data
      |> Jason.decode!()
      |> case do
        %{"specversion" => "0.2", "type" => ^event_type} = cloud_event -> cloud_event
        %{"cloudEventsVersion" => "0.1", "eventType" => ^event_type} = cloud_event -> cloud_event
      end

    {cloud_event, %{state | first_message: nil}}
  end

  @impl true
  def read_welcome_event(state), do: read_event(state, "rig.connection.create")

  @impl true
  def read_subscriptions_set_event(state), do: read_event(state, "rig.subscriptions_set")

  @impl true
  def try_connect_then_disconnect(params \\ []) do
    {:ok, client} = connect(params)
    disconnect(client)
    {:ok, client}
  rescue
    err in [TestClient.ConnectionError] -> {:error, err}
  end
end
