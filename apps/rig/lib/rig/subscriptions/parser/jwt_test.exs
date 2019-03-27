defmodule RIG.Subscriptions.Parser.JWTTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest RIG.Subscriptions.Parser.JWT

  alias Result

  alias Rig.Subscription
  alias RIG.Subscriptions.Parser.JWT, as: SUT

  test "If an extractor defines JWT json_pointers for fields that are valid for the given claims, a subscription is created with a single, conjunctive constraint." do
    claims = %{"givenName" => "alice", "age" => 33}

    extractor_config = %{
      "testevent" => %{
        "name" => %{
          "stable_field_index" => 0,
          "jwt" => %{"json_pointer" => "/givenName"},
          "event" => %{"json_pointer" => "/data/givenName"}
        },
        "age" => %{
          "stable_field_index" => 1,
          "jwt" => %{"json_pointer" => "/age"},
          "event" => %{"json_pointer" => "/data/age"}
        }
      }
    }

    assert {:ok, subscriptions} = SUT.from_jwt_claims(claims, extractor_config)
    assert [subscription] = subscriptions

    assert subscription == %Subscription{
             event_type: "testevent",
             constraints: [%{"name" => "alice", "age" => 33}]
           }
  end

  test "If an extractor defines a JWT json_pointer for a field not present in the given claims, no subscriptions are created." do
    claims = %{}

    extractor_config = %{
      "testevent" => %{
        "name" => %{
          "stable_field_index" => 0,
          "jwt" => %{"json_pointer" => "/givenName"},
          "event" => %{"json_pointer" => "/data/givenName"}
        }
      }
    }

    {:ok, subscriptions} = SUT.from_jwt_claims(claims, extractor_config)
    assert subscriptions == []
  end

  test "If an extractor defines a field but no JWT properties, no subscriptions are created." do
    claims = %{"givenName" => "alice", "age" => 33}

    extractor_config = %{
      "testevent" => %{
        "name" => %{
          "stable_field_index" => 0,
          "event" => %{"json_pointer" => "/data/givenName"}
        },
        "age" => %{
          "stable_field_index" => 1,
          "event" => %{"json_pointer" => "/data/age"}
        }
      }
    }

    {:ok, subscriptions} = SUT.from_jwt_claims(claims, extractor_config)
    assert subscriptions == []
  end

  test "With an empty extractor config, no subscriptions are created." do
    claims = %{"givenName" => "alice", "age" => 33}
    extractor_config = %{}
    {:ok, subscriptions} = SUT.from_jwt_claims(claims, extractor_config)
    assert subscriptions == []
  end
end
