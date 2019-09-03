defmodule RigCloudEvents.Parser do
  @moduledoc """
  Tolerant reader for JSON encoded CloudEvents.
  """
  @type t :: module

  @typedoc "The JSON encoded CloudEvent."
  @type json_string :: String.t()

  @typedoc "A CloudEvents context attribute name."
  @type attribute :: String.t()

  @typedoc "A CloudEvents extension name."
  @type extension :: String.t()

  @typedoc "A JSON Pointer (see [RFC 6901](https://tools.ietf.org/html/rfc6901))."
  @type json_pointer :: String.t()

  @doc """
  Parse a JSON encoded CloudEvent.
  """
  @callback parse(json_string) :: t

  @doc """
  Fetch the value of a CloudEvents context attribute.
  """
  @callback context_attribute(t, attribute) ::
              {:ok, value :: any}
              | {:error, {:not_found, Parser.attribute(), t}}
              | {:error, {:non_scalar_value, Parser.attribute(), t}}
              | {:error, any}

  @doc """
  Fetch the value of a CloudEvents extension attribute.
  """
  @callback extension_attribute(t, extension, attribute) ::
              {:ok, value :: any}
              | {:error, {:not_found, Parser.attribute(), t}}
              | {:error, {:not_an_object | :non_scalar_value, Parser.attribute(), t}}
              | {:error, any}

  @doc """
  Find a specific value using a JSON Pointer.
  """
  @callback find_value(t, json_pointer) ::
              {:ok, value :: any}
              | {:error, {:not_found, location :: String.t(), t}}
              | {:error, {:non_scalar_value, location :: String.t(), t}}
              | {:error, any}
end
