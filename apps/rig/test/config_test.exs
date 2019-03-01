defmodule Rig.ConfigTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Rig.Config

  test "should add rig/priv to cert-path config" do
    config = [
      https: [
        port: 4001,
        otp_app: :rig,
        cipher_suite: :strong,
        certfile: "cert/selfsigned.pem",
        keyfile: "cert/selfsigned_key.des3.pem",
        password: "test"
      ]
    ]

    config = config |> Config.check_and_update_https_config()

    assert config[:https][:certfile]
           |> String.contains?("rig/priv/cert/selfsigned.pem") === true

    assert config[:https][:keyfile]
           |> String.contains?("rig/priv/cert/selfsigned_key.des3.pem") === true

    assert config[:https][:password] |> is_list === true
  end

  test "should set https to false if certfile is empty string" do
    config = [
      https: [
        port: 4001,
        otp_app: :rig,
        cipher_suite: :strong,
        certfile: "",
        keyfile: "",
        password: ""
      ]
    ]

    config = config |> Config.check_and_update_https_config()

    assert config[:https] === false
  end
end
