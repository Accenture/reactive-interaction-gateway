defmodule RigInboundGateway.ApiProxy.Validations do
  @moduledoc """
  Used to validate APIs configuration for reverse proxy.
  Validates use cases such as setting "target" to "kafka", but ommiting "topic" which is required in such case.

  When any error occurs during RIG start -> process will exit.
  When any error occurs during REST API request -> process won't exit, but instead API returns 400 -- bad request.
  """
  use Rig.Config, [:kinesis_request_stream, :kafka_request_topic, :kafka_request_avro]

  alias RigInboundGateway.ApiProxy.Api

  require Logger

  @type error_t :: [{:error, String.t() | atom, atom, String.t()}]
  @type error_list_t :: [{String.t(), error_t()}]
  @type error_map_t :: %{String.t() => [%{(String.t() | atom) => String.t()}]}

  @spec validate_endpoint_target(Api.endpoint()) :: boolean
  def validate_endpoint_target(endpoint) do
    Vex.valid?(endpoint, %{"target" => [inclusion: ["kafka", "kinesis"]]})
  end

  # ---

  @spec with_nested_presence(Api.t(), String.t() | atom, map) :: error_t()
  def with_nested_presence(true, key, map) do
    Vex.errors(map, %{key => [presence: true]})
  end

  def with_nested_presence(_, _, _), do: []

  # ---

  @spec validate_auth_type(Api.t()) :: error_t()
  def validate_auth_type(%{"auth" => %{"use_header" => true}} = api) do
    Vex.errors(api, %{"auth_type" => [inclusion: ["jwt"]]})
  end

  def validate_auth_type(%{"auth" => %{"use_query" => true}} = api) do
    Vex.errors(api, %{"auth_type" => [inclusion: ["jwt"]]})
  end

  def validate_auth_type(_), do: []

  # ---

  @spec validate_auth(error_list_t(), Api.t()) :: error_list_t()
  def validate_auth(errors, %{"auth" => auth, "id" => id} = api) do
    use_header_error =
      Vex.errors(
        auth,
        %{
          "header_name" => [
            presence: [
              if: fn _ -> Vex.valid?(auth, %{"use_header" => [presence: true]}) end
            ]
          ]
        }
      )

    use_query_error =
      Vex.errors(
        auth,
        %{
          "query_name" => [
            presence: [
              if: fn _ -> Vex.valid?(auth, %{"use_query" => [presence: true]}) end
            ]
          ]
        }
      )

    all_errors = use_header_error ++ use_query_error ++ validate_auth_type(api)
    if all_errors == [], do: errors, else: errors ++ [{id, all_errors}]
  end

  def validate_auth(_, _), do: []

  # ---

  @spec validate_secured_endpoint(Api.t(), Api.endpoint()) :: error_t()
  def validate_secured_endpoint(api, %{"secured" => true}) do
    Vex.errors(api, %{"auth_type" => [inclusion: ["jwt"]]})
  end

  def validate_secured_endpoint(_, _), do: []

  # ---

  @spec with_any_error(error_list_t(), integer) :: error_list_t()
  def with_any_error(errors, min_errors \\ 1)
  def with_any_error(errors, min_errors) when length(errors) > min_errors, do: errors
  def with_any_error(_, _), do: []

  # ---

  @spec validate_endpoints(error_list_t(), Api.t()) :: error_list_t()
  def validate_endpoints(
        errors,
        %{"id" => id, "version_data" => %{"default" => %{"endpoints" => endpoints}}} = api
      ) do
    conf = config()

    Enum.reduce(endpoints, [], fn endpoint, acc ->
      topic_presence_config =
        endpoint
        |> validate_endpoint_target()
        |> with_nested_presence("topic", endpoint)

      # DEPRECATED. (Will be removed with the version 3.0.)
      topic_presence =
        endpoint
        |> validate_endpoint_target()
        |> with_nested_presence(:kafka_request_topic, conf)
        |> Enum.concat(topic_presence_config)

      # DEPRECATED. (Will be removed with the version 3.0.)
      stream_presence =
        endpoint
        |> validate_endpoint_target()
        |> with_nested_presence(:kinesis_request_stream, conf)
        |> Enum.concat(topic_presence_config)

      schema_presence_config =
        endpoint
        |> Vex.valid?(%{"schema" => [presence: true]})
        |> with_nested_presence("target", endpoint)

      # DEPRECATED. (Will be removed with the version 3.0.)
      schema_presence =
        conf
        |> Vex.valid?(%{:kafka_request_avro => [presence: true]})
        |> with_nested_presence("target", endpoint)
        |> Enum.concat(schema_presence_config)

      all_errors =
        validate_secured_endpoint(api, endpoint) ++
          with_any_error(topic_presence) ++
          with_any_error(stream_presence) ++ schema_presence

      if all_errors == [], do: acc, else: acc ++ [{"#{id}/#{endpoint["id"]}", all_errors}]
    end)
    |> Enum.concat(errors)
  end

  # ---

  @spec validate_all(Api.t()) :: error_list_t()
  def validate_all(api) do
    []
    |> validate_auth(api)
    |> validate_endpoints(api)
    |> Enum.dedup()
  end

  # ---

  @spec validate!(Api.t()) :: Api.t()
  def validate!(api) do
    errors = validate_all(api)

    if errors != [] do
      log_error(errors)
      Process.exit(self(), :ReverseProxyConfigurationError)
    end

    api
  end

  # ---

  @spec validate(Api.t()) :: {:error, error_list_t()} | {:ok, Api.t()}
  def validate(api) do
    errors = validate_all(api)

    if errors != [] do
      log_error(errors)
      {:error, errors}
    else
      {:ok, api}
    end
  end

  # ---

  @spec to_map(error_list_t()) :: error_map_t()
  def(to_map(errors)) do
    errors
    |> Enum.map(fn {key, value} ->
      {key, Enum.map(value, fn {_, key, _, reason} -> %{key => reason} end)}
    end)
    |> Enum.into(%{})
  end

  # ---

  defp log_error(errors) do
    Logger.error(fn ->
      "Wrong reverse proxy configuration: #{inspect(errors)}"
    end)
  end
end
