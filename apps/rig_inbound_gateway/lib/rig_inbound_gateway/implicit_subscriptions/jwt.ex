defmodule RigInboundGateway.ImplicitSubscriptions.Jwt do
  @moduledoc """
  Create subscriptions based on JWT and extractor file
  """

  require Logger

  use Rig.Config, [:extractor_config_path_or_json]

  alias Rig.EventFilter.Config
  alias RigAuth.Jwt.Utils

  def check_subscriptions([]) do
    Logger.debug("JWT not present in request > no implicit JWT subscriptions will be added")
    []
  end

  def check_subscriptions(jwts) do
    %{extractor_config_path_or_json: extractor_config_path_or_json} = config()
    {:ok, extractor_map} = Config.new(extractor_config_path_or_json)
    claims = extract_token_claims(jwts)
    extractor_map |> map_extractors(claims)
  end

  defp map_extractors(extractor_map, claims) do
    extractor_map
    |> Enum.flat_map(fn {event_type, constraints} ->
      constraints
      |> Enum.map(fn {name, constraint} ->
        get_pointer_values(claims, constraint, name)
      end)
      |> case do
        [nil] ->
          []

        all_constraints ->
          merged_constraints = Enum.concat(all_constraints)
          [%{"eventType" => event_type, "oneOf" => merged_constraints}]
      end
    end)
  end

  defp extract_token_claims(jwts) do
    jwts
    |> Enum.map(fn token ->
      token
      |> String.split(" ", parts: 2)
      |> case do
        [token] ->
          {:ok, claims} = Utils.decode(token)
          claims

        [_scheme, token] ->
          {:ok, claims} = Utils.decode(token)
          claims
      end
    end)
  end

  defp get_pointer_values(jwt_claims, %{"jwt" => %{"json_pointer" => json_pointer}}, name) do
    jwt_claims
    |> Enum.map(fn token ->
      {:ok, value} = JSONPointer.get(token, json_pointer)
      %{name => value}
    end)
  end

  defp get_pointer_values(_jwt_claims, constraint, _name) do
    Logger.warn(fn ->
      "Constraint=#{inspect(constraint)} doesn\'t include key=jwt > skipping implicit subscription creation"
    end)

    nil
  end
end
