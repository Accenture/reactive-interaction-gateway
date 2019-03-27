defmodule RIG.SubscriptionsTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import Joken

  alias RIG.JWT
  alias RIG.Subscriptions
  alias RigInboundGateway.ExtractorConfig

  @jwt_secret_key "my-super-secret-for-this-test"
  @jwt_alg "HS256"
  @jwt_conf %{alg: @jwt_alg, key: @jwt_secret_key}

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
          "stable_field_index" => 1
        },
        "name" => %{
          "event" => %{"json_pointer" => "/data/name"},
          "jwt" => %{"json_pointer" => "/username"},
          "stable_field_index" => 2
        }
      },
      "example" => %{
        "email" => %{
          "event" => %{"json_pointer" => "/data/email"},
          "stable_field_index" => 1
        }
      }
    })

    on_exit(&ExtractorConfig.restore/0)

    :ok
  end

  test "A token may be empty." do
    assert {:ok, []} = Subscriptions.from_token("")
    assert {:ok, []} = Subscriptions.from_token(nil)
  end

  test "should return array with constraints mapped to events when JWT present" do
    jwt = generate_jwt()

    assert Subscriptions.from_token(jwt, @jwt_conf) ==
             {:ok,
              [
                %Rig.Subscription{
                  constraints: [%{"name" => "john"}],
                  event_type: "event_one"
                },
                %Rig.Subscription{
                  constraints: [%{"fullname" => "John Doe", "name" => "john"}],
                  event_type: "event_two"
                }
              ]}
  end

  test "should return error when JWT is using Bearer" do
    jwt = generate_jwt()

    # Works as-is:
    assert {:ok, _} = Subscriptions.from_token(jwt, @jwt_conf)

    # Doesn't work with "Bearer" prepended:
    assert {:error, %Subscriptions.Error{cause: %JWT.DecodeError{}}} =
             Subscriptions.from_token("Bearer #{jwt}", @jwt_conf)
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
