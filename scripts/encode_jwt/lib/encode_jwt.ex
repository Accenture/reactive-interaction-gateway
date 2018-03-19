defmodule EncodeJwt do
  @moduledoc """
  Create JWTs that can be used with RIG, mainly for testing purposes.

  Build the script with `mix escript.build`.
  """
  import Enum

  @switches [
    secret: :string,
    user: :string,
    roles: :string,
    exp: :integer,
    help: :boolean
  ]

  def main(args \\ []) do
    args
    |> parse_args
    |> usage_if_help
    |> jwt
    |> IO.puts()
  end

  defp usage_if_help(opts) do
    if opts[:help] do
      usage() |> IO.puts()
      System.halt(0)
    else
      opts
    end
  end

  defp usage do
    switches =
      @switches
      |> map(fn {k, v} -> "--#{k} <#{v}>" end)
      |> join("\n")

    """
    Helper script to create a JWT that can be used with RIG.

    Usage:

    #{switches}
    """
  end

  defp parse_args(args) do
    {parsed, []} = OptionParser.parse!(args, strict: @switches)
    parsed |> Enum.into(%{})
  rescue
    _ ->
      usage() |> IO.puts()
      System.halt(1)
  end

  defp jwt(opts) do
    import Joken

    %{
      user: opts.user,
      roles:
        opts
        |> Map.get(:roles, "")
        |> String.split(",")
        |> map(&String.trim/1)
        |> filter(&(String.length(&1) > 0)),
      exp: opts.exp,
      jti: random_jti()
    }
    |> token
    |> with_signer(hs256(opts[:secret]))
    |> sign
    |> get_compact
  end

  defp random_jti do
    inspect(System.system_time(:second))
  end
end
