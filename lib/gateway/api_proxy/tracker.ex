defmodule Gateway.ApiProxy.Tracker do
  @moduledoc """
  Encapsulates Phoenix Presence, mainly to ease testing.

  """

  defmodule TrackerBehaviour do
    @moduledoc false
    @callback track(id :: String.t, api :: map, node_name :: String.t) :: {:ok, String.t}
    @callback list() :: [{String.t, %{optional(String.t) => String.t}}]
  end

  @behaviour TrackerBehaviour

  require Logger

  alias Gateway.ApiProxy.PresenceHandler, as: Presence

  @topic "proxy"

  @impl TrackerBehaviour
  def track(id, api, node_name) do
    IO.puts "tracker.ex - TRACK #{id}"
    IO.puts "NODE NAME #{node_name}"
    prev_api = find(id, node_name)
    IO.inspect prev_api

    case compare_api(id, prev_api, api) do
      {:error, :exit} ->
        Logger.warn("There is already most recent API definition with id=#{id} in presence")
        {:error, :exit}
      {:ok, :track} ->
        internal_info = %{
          "ref_number" => 0,
          "node_name" => node_name,
          "timestamp" => Timex.now,
        }
        api_with_internal_info = add_internal_info(api, internal_info)

        Logger.info("Started tracking for new API definition with id=#{id}")
        Phoenix.Tracker.track(
          _tracker = Presence,
          _pid = Process.whereis(Gateway.PubSub),
          @topic,
          _key = id,
          _meta = api_with_internal_info)
      {:ok, :update_no_ref} ->
        Logger.info("API definition with id=#{id} adopted more recent version from other nodes")
        api_with_internal_info = add_internal_info(api, %{"node_name" => node_name})
        update(id, api_with_internal_info)
      {:ok, :update_with_ref} ->
        Logger.info("API definition with id=#{id} adopted new version")
        internal_info = %{
          "ref_number" => prev_api["ref_number"] + 1,
          "node_name" => node_name,
        }
        api_with_internal_info = add_internal_info(api, internal_info)
        update(id, api_with_internal_info)
    end
  end

  defp compare_api(_id, nil, _next_api), do: {:ok, :track}
  defp compare_api(id, {id, prev_api}, next_api) do
    IO.inspect prev_api["ref_number"]
    IO.inspect next_api["ref_number"]

    cond do
      next_api["ref_number"] < prev_api["ref_number"] -> {:error, :exit}
      next_api["ref_number"] > prev_api["ref_number"] -> {:ok, :update_with_ref}
      true -> eval_data_change(id, prev_api, next_api)
    end
  end

  defp eval_data_change(id, prev_api, next_api) do
    prev_apis = find_all(id)
    h_n_of_prev_apis = length(prev_apis) / 2
    IO.puts "HALF NUMBER OF VALID APIS #{h_n_of_prev_apis}"

    next_api_without_meta = next_api |> remove_internal_info

    changed_apis = prev_apis |> Enum.filter(fn({_key, meta}) ->
      api_without_meta =
        meta
        |> remove_internal_info
        |> MapDiff.diff(next_api_without_meta)

      api_without_meta.changed != :equal
    end)
    n_of_changed_apis = length(changed_apis)
    IO.puts "NUMBER OF CHANGED APIS #{n_of_changed_apis}"
    IO.puts "DOES AT LEAST HALF OF NODES CHANGE #{n_of_changed_apis >= h_n_of_prev_apis}"

    cond do
      n_of_changed_apis < h_n_of_prev_apis -> {:error, :exit}
      n_of_changed_apis > h_n_of_prev_apis -> {:ok, :update_no_ref}
      true ->
        next_api["timestamp"]
        |> Timex.after?(prev_api["timestamp"])
        |> eval_time
    end
  end
  
  defp eval_time(false) do
    IO.puts "NEXT TIMESTAMP IS OLDER OR SAME AS PREV TIMESTAMP"
    {:error, :exit}
  end
  defp eval_time(true) do
    IO.puts "NEXT TIMESTAMP IS NEWER THAN PREV TIMESTAMP"
    {:ok, :update_no_ref}
  end
  
  defp add_internal_info(api, internal_info) do
    Map.merge(api, internal_info)
  end

  defp remove_internal_info(api) do
    api
    |> Map.delete(:phx_ref)
    |> Map.delete("node_name")
    |> Map.delete("timestamp")
  end

  def update(id, api) do
    IO.puts "UPDATE #{id}"

    Phoenix.Tracker.update(
      _tracker = Presence,
      _pid = Process.whereis(Gateway.PubSub),
      @topic,
      _key = id,
      _meta = api)
  end

  @impl TrackerBehaviour
  def list do
    Phoenix.Tracker.list(Presence, @topic)
  end

  def find(id, node_name) do
    list() |> Enum.find(fn({key, meta}) -> key == id && meta["node_name"] == node_name end)
  end
  def find_all(id) do
    list() |> Enum.filter(fn({key, _meta}) -> key == id end)
  end
end
