defmodule RigInboundGateway.RateLimit.RateLimitTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import RigInboundGateway.RateLimit, only: [request_passage: 3]

  test "a normal flow with burst_size 1" do
    table_name = :test_rate_limit_normal
    {endpoint, ip} = {"dest", "1.2.3.4"}
    expected_key = "#{endpoint}_#{ip}"
    # The table does not yet exist:
    assert_raise ArgumentError, fn -> :ets.lookup :a, expected_key end
    # Let's request passage, it should work:
    opts = [
      enabled?: true,
      avg_rate_per_sec: 1,
      burst_size: 1,
      current_unix_time: 1,
      table_name: table_name,
    ]
    result = request_passage(endpoint, ip, opts)
    assert result === :ok
    # Now the table exists, and the record should too:
    assert [{expected_key, 0, 1}] === :ets.lookup table_name, expected_key
    # The burst size is 1, so the next request should fail:
    result = request_passage(endpoint, ip, opts)
    assert result === :passage_denied
    # After "waiting" a sec, the token is restored and the request is :ok again:
    opts = Keyword.merge(opts, [current_unix_time: 2])
    result = request_passage(endpoint, ip, opts)
    assert result === :ok
  end

  test "that both endpoint and ip are considered if per_ip? is true" do
    table_name = :test_rate_limit_endpoint_with_ip
    {endpoint, ip1, ip2} = {"dest", "10.0.0.1", "10.0.0.2"}
    opts = [
      enabled?: true,
      per_ip?: true,
      burst_size: 1,
      table_name: table_name,
      current_unix_time: 1,
    ]
    assert :ok == request_passage(endpoint, ip1, opts)
    assert :passage_denied == request_passage(endpoint, ip1, opts)
    assert :ok == request_passage(endpoint, ip2, opts)
    assert :passage_denied == request_passage(endpoint, ip2, opts)
  end

  test "that both the endpoint is considered only if per_ip? is false" do
    table_name = :test_rate_limit_endpoint_without_ip
    {endpoint, ip1, ip2} = {"dest", "10.0.0.1", "10.0.0.2"}
    opts = [
      enabled?: true,
      per_ip?: false,
      burst_size: 1,
      table_name: table_name,
      current_unix_time: 1,
    ]
    assert :ok == request_passage(endpoint, ip1, opts)
    assert :passage_denied == request_passage(endpoint, ip1, opts)
    assert :passage_denied == request_passage(endpoint, ip2, opts)
  end
end
