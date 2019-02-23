defmodule RIG.JWT.HttpCredentials do
  @moduledoc "HTTP header parser."

  @type bearer :: {:bearer, token :: String.t()}
  @type supported_credential :: bearer

  @doc """
  Finds credentials in a given HTTP header value.

  Unsupported credential schemes are filtered out of the result.
  """
  @spec from(String.t()) :: [supported_credential]
  def from(header_value) do
    header_value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reduce([], fn
      "Bearer " <> token, acc -> [{:bearer, token} | acc]
      _, acc -> acc
    end)
  end
end
