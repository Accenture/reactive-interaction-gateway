defmodule RigInboundGateway.ImplicitSubscriptions.JwtTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import Joken

  alias RigInboundGateway.ExtractorConfig
  alias RigInboundGateway.ImplicitSubscriptions.Jwt

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
          "stable_field_index" => 1
        },
        "name" => %{
          "event" => %{"json_pointer" => "/data/name"},
          "jwt" => %{"json_pointer" => "/username"},
          "stable_field_index" => 1
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

  test "should return empty array when no JWT present in headers" do
    assert Jwt.infer_subscriptions([]) == []
  end

  test "should return array with constraints mapped to events when JWT present" do
    jwt = generate_jwt()

    assert Jwt.infer_subscriptions([jwt]) == [
             %{"eventType" => "event_one", "oneOf" => [%{"name" => "john"}]},
             %{
               "eventType" => "event_two",
               "oneOf" => [%{"fullname" => "John Doe"}, %{"name" => "john"}]
             }
           ]
  end

  test "should return array with constraints mapped to events when JWT present with Bearer schema" do
    jwt = "Bearer " <> generate_jwt()

    assert Jwt.infer_subscriptions([jwt]) == [
             %{"eventType" => "event_one", "oneOf" => [%{"name" => "john"}]},
             %{
               "eventType" => "event_two",
               "oneOf" => [%{"fullname" => "John Doe"}, %{"name" => "john"}]
             }
           ]
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
