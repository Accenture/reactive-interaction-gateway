defmodule RigInboundGateway.ApiProxy.Validations do
  @moduledoc """
  TODO

  """

  use Rig.Config, []
  require Logger

  def validate_endpoint_target(endpoint) do
    Vex.valid?(endpoint, %{"target" => [inclusion: ["kafka", "kinesis"]]})
  end

  # ---

  def validate_nested_presence(true, key, primary_map) do
    Vex.errors(
      primary_map,
      %{
        key => [
          presence: true
        ]
      }
    )
  end

  def validate_nested_presence(_, _, _), do: []

  # ---

  def validate_auth_type(%{"auth" => %{"use_header" => true}} = api) do
    Vex.errors(api, %{"auth_type" => [inclusion: ["jwt"]]})
  end

  def validate_auth_type(%{"auth" => %{"use_query" => true}} = api) do
    Vex.errors(api, %{"auth_type" => [inclusion: ["jwt"]]})
  end

  def validate_auth_type(_), do: []

  # ---

  def validate_auth(errors, %{"auth" => auth, "id" => id} = api) do
    header_error =
      Vex.errors(
        auth,
        %{
          "header_name" => [
            presence: [
              if: fn _ ->
                Vex.valid?(auth, %{"use_header" => [presence: true]})
              end
            ]
          ]
        }
      )

    query_error =
      Vex.errors(
        auth,
        %{
          "query_name" => [
            presence: [
              if: fn _ ->
                Vex.valid?(auth, %{"use_query" => [presence: true]})
              end
            ]
          ]
        }
      )

    all_errors = header_error ++ query_error ++ validate_auth_type(api)
    if all_errors == [], do: errors, else: errors ++ [{id, all_errors}]
  end

  def validate_auth(_, _), do: []

  # ---

  def validate_secured_endpoint(api, %{"secured" => true}) do
    Vex.errors(api, %{"auth_type" => [inclusion: ["jwt"]]})
  end

  def validate_secured_endpoint(_, _), do: []

  # ---

  def with_error(errors, min_errors \\ 1)
  def with_error(errors, min_errors) when length(errors) > min_errors, do: errors
  def with_error(_, _), do: []

  # ---

  def validate_endpoints(
        errors,
        %{"id" => id, "version_data" => %{"default" => %{"endpoints" => endpoints}}} = api
      ) do
    conf = config()

    res =
      Enum.reduce(endpoints, [], fn endpoint, acc ->
        topic_presence_config =
          endpoint
          |> validate_endpoint_target()
          |> validate_nested_presence("topic", endpoint)

        topic_presence =
          endpoint
          |> validate_endpoint_target()
          |> validate_nested_presence(:kafka_request_topic, conf)
          |> Enum.concat(topic_presence_config)

        stream_presence =
          endpoint
          |> validate_endpoint_target()
          |> validate_nested_presence(:kinesis_request_stream, conf)
          |> Enum.concat(topic_presence_config)

        schema_presence_config =
          endpoint
          |> Vex.valid?(%{"schema" => [presence: true]})
          |> validate_nested_presence("target", endpoint)

        schema_presence =
          conf
          |> Vex.valid?(%{:kafka_request_avro => [presence: true]})
          |> validate_nested_presence("target", endpoint)
          |> Enum.concat(schema_presence_config)

        all_errors =
          validate_secured_endpoint(api, endpoint) ++
            with_error(topic_presence) ++
            with_error(stream_presence) ++ with_error(schema_presence, 0)

        if all_errors == [], do: acc, else: acc ++ [{"#{id}/#{endpoint["id"]}", all_errors}]
      end)

    errors ++ res
  end

  # ---

  def validate!(api) do
    errors =
      []
      |> validate_auth(api)
      |> validate_endpoints(api)
      |> Enum.dedup()

    # |> Enum.map(fn a ->
    #   IO.inspect(a)
    #   {:error, key, _, message} = a
    #   IO.inspect(key)
    #   IO.inspect(message)
    #   "#{key}=#{message}"
    # end)

    # IO.inspect(errors, label: "ALL ERRORS")

    if errors != [] do
      Logger.error(fn ->
        "Wrong reverse proxy configuration: #{inspect(errors)}"
      end)

      Process.exit(self(), :ReverseProxyConfigurationError)
    end

    api
  end

  def validate(api) do
    errors =
      []
      |> validate_auth(api)
      |> validate_endpoints(api)
      |> Enum.dedup()

    # |> Enum.map(fn a ->
    #   IO.inspect(a)
    #   {:error, key, _, message} = a
    #   IO.inspect(key)
    #   IO.inspect(message)
    #   "#{key}=#{message}"
    # end)

    # IO.inspect(errors, label: "ALL ERRORS")

    if errors != [] do
      Logger.error(fn ->
        "Wrong reverse proxy configuration: #{inspect(errors)}"
      end)

      {:error, errors}
    else
      {:ok, api}
    end
  end

  def to_map(errors) do
    errors
    |> Enum.map(fn {key, value} ->
      {key, Enum.map(value, fn {_, key, _, reason} -> %{key => reason} end)}
    end)
    |> Enum.into(%{})
  end
end
