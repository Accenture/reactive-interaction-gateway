defmodule RigInboundGateway.ImplicitSubscriptions.JwtTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import Joken

  alias RigInboundGateway.ImplicitSubscriptions.Jwt

  @jwt_secret_key "mysecret"

  test "should return empty array when no JWT present in headers" do
    assert Jwt.check_subscriptions([]) == []
  end

  test "should return array with constraints mapped to events when JWT present" do
    jwt = generate_jwt()

    assert Jwt.check_subscriptions([jwt]) == [
             %{"eventType" => "event_one", "oneOf" => [%{"name" => "john"}]},
             %{
               "eventType" => "event_two",
               "oneOf" => [%{"fullname" => "John Doe"}, %{"name" => "john"}]
             }
           ]
  end

  test "should return array with constraints mapped to events when JWT present with Bearer schema" do
    jwt = "Bearer " <> generate_jwt()

    assert Jwt.check_subscriptions([jwt]) == [
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
