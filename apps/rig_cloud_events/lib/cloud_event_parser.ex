defmodule CloudEventParser do
  @moduledoc false
  @type t :: module
  @callback parse(t) ::
              {:ok, t}
              | {:error, :invalid_json, json_decode_error :: any}
              | {:error, :illegal_field, parse_error :: any}
end
