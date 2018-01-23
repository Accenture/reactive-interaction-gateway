defmodule RigInboundGateway.RateLimit do
  @moduledoc """
  Allow only a certain amount of requests per seconds per endpoint (per IP).

  For synchronizing the corresponding state between the short-lived request
  processes, an ETS table is used for optimal performance.
  """
  use Rig.Config,
    [:table_name, :enabled?, :per_ip?, :avg_rate_per_sec, :burst_size, :sweep_interval_ms]
  import Ex2ms
  import RigInboundGateway.RateLimit.Common, only: [now_unix: 0, ensure_table: 1]

  @doc """
  Request passage to a specific endpoint, from a given IP.

  Depending on the granularity, the endpoint might be the hostname of the
  target host, or the target socket, e.g., hostname <> ":" <> port.

  Calling this function always cause a _side effect_: internally, the request
  is recorded. Depending on previous calls, the function returns either :ok
  or :passage_denied. The latter means that the rate limit for the given
  endpoint (and source IP if per_ip? is true) has been reached, which means
  that the request in question should be blocked.
  """
  @spec request_passage(String.t, String.t | nil, %{} | []) :: :ok | :passage_denied
  def request_passage(endpoint, ip \\ nil, opts \\ []) do
    do_request_passage(endpoint, ip, Enum.into(opts, config()))
  end

  defp do_request_passage(_endpoint, _ip, %{enabled?: false}) do
    :ok
  end
  defp do_request_passage(endpoint, _ip, %{per_ip?: false} = opts) do
    make_request(_key = endpoint, opts)
  end
  defp do_request_passage(endpoint, nil, opts) do
    make_request(_key = endpoint, opts)
  end
  defp do_request_passage(endpoint, ip, opts) do
    make_request(_key = endpoint <> "_" <> ip, opts)
  end

  defp make_request(key, %{avg_rate_per_sec: avg_rate_per_sec,
                           burst_size: burst_size, table_name: tab} = opts) do
    now = Map.get(opts, :current_unix_time, now_unix())
    # Make sure the ets table exists:
    ensure_table(tab)
    # Make sure a record for this key is present:
    :ets.insert_new tab, {key, _tokens = burst_size, _last_used = now}
    # Update record and check if successful:
    consume_token_matchspec =
      fun do {^key, n_tokens, last_used}
      when n_tokens + (^now - last_used) * ^avg_rate_per_sec >= 1
      ->
        {^key, n_tokens + (^now - last_used) * ^avg_rate_per_sec - 1, ^now}
      end
    result = case :ets.select_replace(tab, consume_token_matchspec) do
      0 -> :passage_denied
      1 -> :ok
    end
    # It's not possible to use `min` in a match_spec, so we're cleaning up now:
    cap_to_burst_size_matchspec =
      fun do {^key, n_tokens, last_used} when n_tokens > ^burst_size ->
        {^key, ^burst_size, last_used}
      end
    :ets.select_replace(tab, cap_to_burst_size_matchspec)
    # Return :ok | :passage_denied
    result
  end
end
