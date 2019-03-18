defmodule RIG.SubscriptionsTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import Joken

  alias RIG.Subscriptions
  alias RigInboundGateway.ExtractorConfig

  @jwt_secret_key "mysecret"

  setup do
    ExtractorConfig.set(%{
      "event_one" => %{
        "name" => %{
          "event" => %{"json_pointer" => "/data/name"},
          "jwt" => %{"json_pointer" => "/username"},
          "stable_field_index" => 1
        }
      },
      "event_two" => %{
        "fullname" => %{
          "event" => %{"json_pointer" => "/data/fullname"},
          "jwt" => %{"json_pointer" => "/fullname"},
          "stable_field_index" => 2
        },
        "name" => %{
          "event" => %{"json_pointer" => "/data/name"},
          "jwt" => %{"json_pointer" => "/username"},
          "stable_field_index" => 3
        }
      },
      "example" => %{
        "email" => %{
          "event" => %{"json_pointer" => "/data/email"},
          "stable_field_index" => 4
        }
      }
    })

    on_exit(&ExtractorConfig.restore/0)

    :ok
  end

  test "should return empty array when no JWT present" do
    assert Subscriptions.from_token("") == []
  end

  test "should return array with constraints mapped to events when JWT present" do
    jwt = generate_jwt()

    assert Subscriptions.from_token(jwt, %{key: "mysecret", alg: "HS256"}) == [
             ok: %Rig.Subscription{
               constraints: [%{"name" => "john"}],
               event_type: "event_one"
             },
             ok: %Rig.Subscription{
               constraints: [%{"fullname" => "John Doe", "name" => "john"}],
               event_type: "event_two"
             }
           ]
  end

  test "should return error when JWT is using Bearer" do
    jwt = "Bearer " <> generate_jwt()
    assert Subscriptions.from_token(jwt) == [error: "JWT: Invalid signature"]
  end

  defp generate_jwt do
    token()
    |> with_exp
    |> with_signer(@jwt_secret_key |> hs256)
    |> with_claim("username", "john")
    |> with_claim("fullname", "John Doe")
    |> sign
    |> get_compact
  end
end
