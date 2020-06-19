defmodule RigInboundGateway.ApiProxy.Validations do
  @moduledoc """
  Used to validate APIs configuration for reverse proxy.
  Validates use cases such as setting "target" to "kafka" but not "topic", which is required in such case.

  When any error occurs during RIG start -> process will exit.
  When any error occurs during REST API request -> process won't exit, but instead API returns 400 -- bad request.
  """
  use Rig.Config, [:kinesis_request_stream, :kafka_request_topic, :kafka_request_avro, :system]

  alias RigInboundGateway.ApiProxy.Api

  require Logger

  @type error_t :: [{:error, String.t() | atom, atom, String.t()}]
  @type error_list_t :: [{String.t(), error_t()}]
  @type error_map_t :: %{String.t() => [%{(String.t() | atom) => String.t()}]}

  @spec validate_endpoint_target(Api.endpoint(), [String.t()]) :: boolean
  def validate_endpoint_target(endpoint, targets) do
    Vex.valid?(endpoint, %{"target" => [inclusion: targets]})
  end

  # ---

  @spec with_nested_presence(boolean, String.t() | atom, map) :: error_t()
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
    merge_errors(errors, [{id, all_errors}])
  end

  def validate_auth(errors, _), do: errors

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
        |> validate_endpoint_target(["kafka", "kinesis"])
        |> with_nested_presence("topic", endpoint)

      # DEPRECATED. (Will be removed with the version 3.0.)
      topic_presence =
        endpoint
        |> validate_endpoint_target(["kafka"])
        |> with_nested_presence(:kafka_request_topic, conf)
        |> Enum.concat(topic_presence_config)

      # DEPRECATED. (Will be removed with the version 3.0.)
      stream_presence =
        endpoint
        |> validate_endpoint_target(["kinesis"])
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
          with_any_error(stream_presence) ++
          schema_presence ++
          validate_string(endpoint, "id") ++
          validate_string(endpoint, "path") ++ validate_string(endpoint, "method")

      merge_errors(acc, [{"#{id}/#{endpoint["id"]}", all_errors}])
    end)
    |> Enum.concat(errors)
  end

  def validate_endpoints(errors, _), do: errors

  # ---

  @spec type_validation(map, String.t(), String.t(), function) :: error_list_t()
  def type_validation(map, key, type, fun) do
    Vex.errors(
      map,
      %{
        key => fn key ->
          if fun.(key) do
            :ok
          else
            {:error, "must be #{type}"}
          end
        end
      }
    )
  end

  # ---

  @spec validate_string(map, String.t()) :: error_list_t()
  def validate_string(map, key) do
    type_validation(map, key, "string", &is_binary/1) ++
      Vex.errors(map, %{key => [length: [min: 1]]})
  end

  # ---

  @spec validate_integer(map, String.t()) :: error_list_t()
  def validate_integer(map, key) do
    type_validation(map, key, "integer", &is_integer/1)
  end

  # ---

  @spec validate_list(map, String.t()) :: error_list_t()
  def validate_list(map, key) do
    type_validation(map, key, "list", &is_list/1)
  end

  # ---

  @spec validate_proxy(Api.t()) :: error_list_t()
  def validate_proxy(%{"proxy" => proxy}) do
    validate_string(proxy, "target_url") ++ validate_integer(proxy, "port")
  end

  def validate_proxy(_), do: []

  # ---

  @spec validate_version_data(Api.t()) :: error_list_t()
  def validate_version_data(%{"version_data" => version_data}) do
    keys = Map.keys(version_data)

    if length(keys) > 0 do
      Enum.reduce(keys, [], fn key, acc ->
        endpoints_errors = version_data |> Map.get(key) |> validate_list("endpoints")
        acc ++ endpoints_errors
      end)
    else
      [{:error, "version_data", :presence, "must have at least one version, e.g. default"}]
    end
  end

  def validate_version_data(_), do: []

  # ---

  @spec validate_required_props(error_list_t(), Api.t()) :: error_list_t()
  def validate_required_props(
        errors,
        api
      ) do
    api_errors =
      validate_string(api, "id") ++
        validate_string(api, "name") ++
        Vex.errors(api, %{"proxy" => [presence: true]}) ++
        validate_proxy(api) ++
        Vex.errors(api, %{"version_data" => [presence: true]}) ++
        validate_version_data(api)

    merge_errors(errors, [{"api", api_errors}])
  end

  # ---

  @spec validate_all(Api.t()) :: error_list_t()
  def validate_all(api) do
    []
    |> validate_required_props(api)
    |> validate_auth(api)
    |> validate_endpoints(api)
    |> Enum.dedup()
  end

  # ---

  @spec validate!(Api.t()) :: Api.t()
  def validate!(api) do
    conf = config()
    errors = validate_all(api)

    if errors != [] do
      log_error(errors)
      conf.system.stop()
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

  # ---

  defp merge_errors(current_errors, [{_key, []}]), do: current_errors
  defp merge_errors(current_errors, new_errors), do: current_errors ++ new_errors
end
