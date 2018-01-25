defmodule RigInboundGateway.RateLimit.SweeperTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import RigInboundGateway.RateLimit, only: [request_passage: 3]
  import RigInboundGateway.RateLimit.Sweeper, only: [sweep: 1]

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
end
