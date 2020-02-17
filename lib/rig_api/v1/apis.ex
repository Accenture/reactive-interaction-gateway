defmodule RigApi.V1.APIs do
  @moduledoc "CRUD controller for the reverse-proxy settings."
  use Rig.Config, [:rig_proxy]
  use RigApi, :controller
  use PhoenixSwagger

  alias RigInboundGateway.ApiProxy.Validations

  require Logger

  @prefix "/v1"

  swagger_path :list_apis do
    get(@prefix <> "/apis")
    summary("List current proxy API-definitions.")
    response(200, "Ok", Schema.ref(:ProxyAPIList))
  end

  def list_apis(conn, _params) do
    %{rig_proxy: proxy} = config()
    api_defs = proxy.list_apis(proxy)
    active_apis = for {_, api} <- api_defs, api["active"], do: api
    send_response(conn, 200, active_apis)
  end

  # ---

  swagger_path :get_api_detail do
    get(@prefix <> "/apis/{apiId}")
    summary("Obtain details on a proxy API-definition.")

    parameters do
      apiId(:path, :string, "API definition identifier", required: true, example: "new-service")
    end

    response(200, "Ok", Schema.ref(:ProxyAPI))
    response(404, "Doesn't exist", Schema.ref(:ProxyAPIResponse))
  end

  def get_api_detail(conn, params) do
    %{"id" => id} = params

    case get_active_api(id) do
      api when api == nil or api == :inactive ->
        send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})

      {_id, api} ->
        send_response(conn, 200, api)
    end
  end

  # ---

  swagger_path :add_api do
    post(@prefix <> "/apis")
    summary("Register a new proxy API-definition.")

    parameters do
      proxyAPI(
        :body,
        Schema.ref(:ProxyAPI),
        "The details for the new Proxy endpoint",
        required: true
      )
    end

    response(201, "Ok", Schema.ref(:ProxyAPIResponse))
    response(409, "Already exists", Schema.ref(:ProxyAPIResponse))
  end

  def add_api(conn, params) do
    %{"id" => id} = params
    %{rig_proxy: proxy} = config()

    with {:ok, _api} <- Validations.validate(params),
         nil <- proxy.get_api(proxy, id),
         {:ok, _phx_ref} <- proxy.add_api(proxy, id, params) do
      send_response(conn, 201, %{message: "ok"})
    else
      {_id, %{"active" => true}} ->
        send_response(conn, 409, %{message: "API with id=#{id} already exists."})

      {:error, errors} ->
        send_response(conn, 400, Validations.to_map(errors))

      {_id, %{"active" => false} = prev_api} ->
        {:ok, _phx_ref} = proxy.replace_api(proxy, id, prev_api, params)
        send_response(conn, 201, %{message: "ok"})
    end
  end

  # ---

  swagger_path :update_api do
    put(@prefix <> "/apis/{apiId}")
    summary("Update a proxy API-definition.")

    parameters do
      apiId(:path, :string, "API definition identifier", required: true, example: "new-service")

      proxyAPI(
        :body,
        Schema.ref(:ProxyAPI),
        "The details for the new Proxy endpoint",
        required: true
      )
    end

    response(200, "Ok", Schema.ref(:ProxyAPIResponse))
    response(404, "Doesn't exist", Schema.ref(:ProxyAPIResponse))
  end

  def update_api(conn, params) do
    %{"id" => id} = params

    with {:ok, _api} <- Validations.validate(params),
         {_id, current_api} <- get_active_api(id),
         {:ok, _phx_ref} <- merge_and_update(id, current_api, params) do
      send_response(conn, 200, %{message: "ok"})
    else
      {:error, errors} ->
        send_response(conn, 400, Validations.to_map(errors))

      api when api == nil or api == :inactive ->
        send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
    end
  end

  # ---

  swagger_path :deactivate_api do
    delete(@prefix <> "/apis/{apiId}")
    summary("Deactivate a proxy API-definition.")

    parameters do
      apiId(:path, :string, "API definition identifier", required: true, example: "new-service")
    end

    response(204, "")
    response(404, "Doesn't exist", Schema.ref(:ProxyAPIResponse))
  end

  def deactivate_api(conn, params) do
    %{"id" => id} = params
    %{rig_proxy: proxy} = config()

    with {_id, _current_api} <- get_active_api(id),
         {:ok, _phx_ref} <- proxy.deactivate_api(proxy, id) do
      send_response(conn, :no_content)
    else
      api when api == nil or api == :inactive ->
        send_response(conn, 404, %{message: "API with id=#{id} doesn't exists."})
    end
  end

  # ---

  defp get_active_api(id) do
    %{rig_proxy: proxy} = config()

    with {id, current_api} <- proxy.get_api(proxy, id),
         true <- current_api["active"] == true do
      {id, current_api}
    else
      nil -> nil
      false -> :inactive
      _ -> :error
    end
  end

  # ---

  defp merge_and_update(id, current_api, updated_api) do
    %{rig_proxy: proxy} = config()
    merged_api = current_api |> Map.merge(updated_api)
    proxy.update_api(proxy, id, merged_api)
  end

  # ---

  defp send_response(conn, :no_content) do
    conn
    |> put_status(:no_content)
    |> text("")
  end

  defp send_response(conn, status_code, body \\ %{}) do
    conn
    |> put_status(status_code)
    |> json(body)
  end

  # ---

  def swagger_definitions do
    %{
      ProxyAPI:
        swagger_schema do
          title("Proxy API Object")
          description("An Proxy API object - Is used for creating/updating/reading")

          properties do
            id(:string, "Proxy API ID", required: true, example: "new-service")
            name(:string, "Proxy API Name", required: true, example: "new-service")
            auth_type(:string, "Authorization type", required: false, example: "jwt")

            auth(
              Schema.new do
                properties do
                  use_header(:boolean, "Authorization Header Usage", default: false, example: true)

                  header_name(:string, "Authorization Header Name",
                    required: false,
                    example: "Authorization"
                  )

                  use_query(:boolean, "Authorization Header Query Usage",
                    default: false,
                    example: false
                  )

                  query_name(:string, "Authorization Header Query Name", required: false)
                end
              end
            )

            timestamp(:string, "creation timestamp",
              required: false,
              example: "2018-12-17T10:38:06.334013Z"
            )

            transform_request_headers(
              Schema.new do
                properties do
                  add_headers(
                    Schema.new do
                      properties do
                        my_header_name(:string, "New header value", example: "some header value")
                      end
                    end
                  )
                end
              end
            )

            ref_number(:integer, "reference number", required: false, example: 0)
            node_name(:string, "Node name", required: false, example: "nonode@nohost")
            active(:boolean, "ID Status", required: false, example: true)
            phx_ref(:string, "Phoenix Reference", required: false, example: "ewTJVcM7Bzc=")
            versioned(:boolean, "is Versioned Endpoint?", default: false, example: false)

            version_data(
              Schema.new do
                properties do
                  default(
                    Schema.new do
                      properties do
                        endpoints(Schema.ref(:ProxyAPIEndpointArray))
                      end
                    end
                  )
                end
              end
            )

            proxy(
              Schema.new do
                properties do
                  use_env(
                    :boolean,
                    "Whether to take the 'target_url' from environment variable or not",
                    default: true,
                    example: true
                  )

                  target_url(:string, "Proxy Target URL", required: true, example: "IS_HOST")
                  port(:integer, "Proxy Port", required: true, example: 6666)
                end
              end
            )
          end
        end,
      ProxyAPIEndpointArray:
        swagger_schema do
          title("Proxy API Endpoint Array")
          description("Array of Endpoints for the Proxy API")
          type(:array)
          items(Schema.ref(:ProxyAPIEndpoint))
        end,
      ProxyAPIEndpoint:
        swagger_schema do
          title("Proxy API Endpoint")
          description("Endpoint for the Proxy API for Request")

          properties do
            id(:string, "Endpoint ID", required: true, example: "get-auth-register")

            path(:string, "Endpoint path. Curly braces may be used to ignore parts of the path.",
              required: true,
              example: "/auth/register/{user}"
            )

            path_regex(
              :string,
              "Endpoint path, given as a regular expression (note that JSON requires escaping backslash characters).",
              required: false,
              example: "/auth/register/(.+)"
            )

            path_replacement(
              :string,
              "If given, the request path is rewritten. When used with `path_regex`, capture groups can be referenced by number (note that JSON requires escaping backslash characters).",
              required: false,
              example: ~S"/auth/register/\1"
            )

            method(:string, "Endpoint HTTP method", required: true, example: "GET")
            secured(:boolean, "Endpoint Security", default: false, example: false)

            transform_request_headers(:boolean, "Transform request headers",
              default: false,
              example: false
            )

            target(:string, "Request target - HTTP, Kafka or Kinesis",
              default: "http",
              example: "http"
            )

            topic(:string, "Kafka/Kinesis topic", example: "kafka-topic")
            schema(:string, "Kafka Avro schema", example: "avro-schema")

            response_from(:string, "Wait for asynchronnous response from HTTP, Kafka or Kinesis",
              default: "http",
              example: "http"
            )
          end
        end,
      ProxyAPIResponse:
        swagger_schema do
          title("Proxy API Response")
          description("Proxy API Response")

          properties do
            message(:string, "Response", required: true, example: "ok")
          end
        end,
      ProxyAPIList:
        swagger_schema do
          title("Proxy API List")
          description(" A List of parameterized Proxy APIs")
          type(:array)
          items(Schema.ref(:ProxyAPI))
        end
    }
  end
end
