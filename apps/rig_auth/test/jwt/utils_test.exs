defmodule RigAuth.Jwt.UtilsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use RigAuth.ConnCase

  alias RigAuth.Jwt.Utils

  setup do
    System.put_env("JWT_SECRET_KEY", "mysecret")
    System.put_env("JWT_ALG", "HS256")
  end

  describe "decode/1" do
    test "should return decoded jwt payload with valid jwt" do
      jwt = generate_jwt()
      assert {:ok, _decoded_payload} = Utils.decode(jwt)
    end

    test "should return error with invalid jwt" do
      jwt = "badtoken"
      assert {:error, "Invalid signature"} = Utils.decode(jwt)
    end
  end

  describe "valid?/1" do
    test "should return true with valid jwt using RS256" do
      System.put_env("JWT_SECRET_KEY", "-----BEGIN CERTIFICATE-----\nMIICVzCCAcACCQC6Bxn5zZYgBzANBgkqhkiG9w0BAQsFADBwMQswCQYDVQQGEwJx\ndzEMMAoGA1UECAwDcXdlMQwwCgYDVQQHDANxd2UxDDAKBgNVBAoMA3F3ZTEMMAoG\nA1UECwwDcXdlMQwwCgYDVQQDDANxd2UxGzAZBgkqhkiG9w0BCQEWDHF3ZUBtYWls\nLmNvbTAeFw0xODA3MjMxMjA1MTFaFw0yMzA3MjIxMjA1MTFaMHAxCzAJBgNVBAYT\nAnF3MQwwCgYDVQQIDANxd2UxDDAKBgNVBAcMA3F3ZTEMMAoGA1UECgwDcXdlMQww\nCgYDVQQLDANxd2UxDDAKBgNVBAMMA3F3ZTEbMBkGCSqGSIb3DQEJARYMcXdlQG1h\naWwuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQChEGtKvkROJocIBNxT\n0inEGEdQPxqvbFol2cMNiQikg7DCx91qc2FQ2hfZSuJiVcQSfVfJvyVO66pM7+bZ\nV/845LhDaUUhzp18pv0PGrIIxNMVD+A25vwq9ay6qlOZz1LNW1OSWpUlqK0Cw/LD\nlO6qFQLVNfudC0hRpVKLYC3hvQIDAQABMA0GCSqGSIb3DQEBCwUAA4GBAJNtoxWp\n0gC1437hF09a8MkCxh2JrtZTJLUozYedwtmkBFhHi1vvpMgFRkPPaGnSI14H4nyJ\nSBjUBRWLkf0+NKMP8OR8VW2qQ2F/o0fkcW+3CHBt+8b3basDxVb2ooFq599P1qB4\n3R0T687G1c8pQ98CBN5gaBvtNldenM0QxXhn\n-----END CERTIFICATE-----")
      System.put_env("JWT_ALG", "RS256")

      jwt =
        "-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQChEGtKvkROJocIBNxT0inEGEdQPxqvbFol2cMNiQikg7DCx91q\nc2FQ2hfZSuJiVcQSfVfJvyVO66pM7+bZV/845LhDaUUhzp18pv0PGrIIxNMVD+A2\n5vwq9ay6qlOZz1LNW1OSWpUlqK0Cw/LDlO6qFQLVNfudC0hRpVKLYC3hvQIDAQAB\nAoGAKAWpc4g19ulx8lcq3JVDlZum1NTpb5/QAsnKwylDAYZLvQrnBRWon+uhs3f9\nKww+zY1h7BrYTXUX+0g9p9JK89Ysto2HncjEC9vMm8Gb0feFcBDOJlYrom1SA47N\n+MqJeg1LiDfHIVBXs4W7h5u1kFZhN6MNtYyzOsKkilL7PmECQQDV3Tpi/i3kyMSw\nGCYdsDUHE/sMGIW9VaetgYdvHDd+tPO3mwMe0lrItUyNtzDrJR4K/MmI6sWP4raN\nd4mfnf0lAkEAwMwW/urkQBLNgNRpPojiWvy2+ZsXmtW15qaWlaEffzjfFQ2IoEzs\nLZe6Rsj4BZ7p53JXILJS3JzevQFFEpyKuQJAVwFHjZpmxVrAWfuZFh7nk9eXHJal\nYh+EtduqY5ORKCUpuZqArHtbn6fSWx0Z87AIBuRMgT0x3pWXOvpUrPEzWQJAccuE\nfy3xTwhKF5JIFEsDH6Ut8qHiCte9J8iH9QVG6/aLZYe5brQ4aqi1n/YavmaPtLY+\nSuQ2GFTW+0P2mweesQJBAKic+GSd/eNTBnJUJsTJMuZjGaHyfvqd0LWVGnQx7xPM\n4I6jG6djGZI1+ImIxIkd+KPuTeEYjFzTEN+rzcoUtLw=\n-----END RSA PRIVATE KEY-----"
        |> generate_jwt
      assert Utils.valid?(jwt)
    end

    test "should return true with valid jwt using HS256" do
      jwt = generate_jwt()
      assert Utils.valid?(jwt)
    end

    test "should return false with invalid jwt" do
      jwt = "badtoken"
      refute Utils.valid?(jwt)
    end
  end
end
