defmodule RIG.SessionTest do
  @moduledoc false
  use ExUnit.Case

  alias RIG.Session

  test "Blacklisting a token with zero validity is a no-op." do
    jti = "123456"
    Session.blacklist(jti, _validity_period_s = 0)
    assert not Session.blacklisted?(jti)
  end

  test "Blacklisting a token with positive validity adds it to the blacklist." do
    jti = "234567"
    Session.blacklist(jti, _validity_period_s = 60)
    assert Session.blacklisted?(jti)
  end

  test "Blacklisting a token asks existing connections associated with that token to terminate." do
    jti = "345678"

    # Register the test process as a connection:
    Session.register_connection(jti, self())

    # Make sure we don't receive the termination message right away:
    refute_receive {:session_killed, _}

    # Blacklist the token, which should cause the termination message to be sent to the
    # (fake) connection:
    Session.blacklist(jti, _validity_period_s = 60)

    # The session is now officially blacklisted..
    assert Session.blacklisted?(jti)
    # ..and the (fake) connection process has received the termination message:
    assert_receive {:session_killed, ^jti}
  end
end
