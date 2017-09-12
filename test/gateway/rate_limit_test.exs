defmodule Gateway.RateLimitTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Gateway.RateLimit
  import Gateway.RateLimit, only: [request_passage: 3]
  import Gateway.RateLimit.Sweeper, only: [sweep: 1]

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

  test "the sweeper removes all records with n_tokens >= burst_size" do
    table_name = :test_rate_limit_sweeper_removal
    {first_endpoint, second_endpoint, ip} = {"first", "second", "1.2.3.4"}
    opts = [
      enabled?: true,
      avg_rate_per_sec: 2,
      burst_size: 4,
      table_name: table_name,
      current_unix_time: 1,
    ]
    # The burst size is 4, so we should be able to make 4 requests:
    for _ <- 1..4 do
      :ok = request_passage(first_endpoint, ip, opts)
      :ok = request_passage(second_endpoint, ip, opts)
    end
    :passage_denied = request_passage(first_endpoint, ip, opts)
    :passage_denied = request_passage(second_endpoint, ip, opts)
    # The sweeper doesn't affect records with no tokens:
    assert 0 == sweep(opts)
    # The sweeper doesn't affect records with some tokens:
    opts = Keyword.merge(opts, [current_unix_time: 2])  # add 2 tokens
    :ok = request_passage(second_endpoint, ip, opts)  # updates last_used
    assert 0 == sweep(opts)  # all records are kept
    # The sweeper removes records with all tokens (all = burst size):
    opts = Keyword.merge(opts, [current_unix_time: 3])  # add 2 more tokens
    assert 1 == sweep(opts)  # only the first record is removed, the other has 3 tokens
    assert 0 == sweep(opts)
    opts = Keyword.merge(opts, [current_unix_time: 10])  # now we go over board here
    assert 1 == sweep(opts)  # the remaining record is removed
    assert 0 == sweep(opts)
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

  test "integration with proxy" do
    Bypass.open(port: 7070)
    |> Bypass.expect(&(Plug.Conn.resp(&1, 200, "")))

    call_endpoint = fn ->
      conn =
        Phoenix.ConnTest.build_conn(:post, "/is/auth")
        |> GatewayWeb.Router.call([])
      conn.status
    end

    %{burst_size: burst_size, table_name: table} = RateLimit.Common.settings()
    for _ <- 1..burst_size do
      assert call_endpoint.() == 200
    end
    assert call_endpoint.() == 429  # too many requests

    :ets.delete(table)
  end
end
