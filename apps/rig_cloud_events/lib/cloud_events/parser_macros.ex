defmodule CloudEvents.ParserMacros do
  @moduledoc false

  # ---

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro nonempty_string(json_name, var_name, opts \\ []) do
    atom_name = String.to_atom(var_name)
    function_name = atom_name
    bang_function_name = String.to_atom(var_name <> "!")

    required? = Keyword.get(opts, :required?, true)

    fallback =
      if required? do
        quote do
          def unquote(function_name)(_), do: {:illegal_field, unquote(atom_name), :missing}
        end
      else
        quote do
          def unquote(function_name)(_), do: {:ok, nil}
        end
      end

    quote do
      # If passed a struct no validation is done:
      def unquote(function_name)(%__MODULE__{unquote(atom_name) => value}),
        do: value

      # Fail if the value is not a string (binary):
      def unquote(function_name)(%{unquote(json_name) => value})
          when not is_binary(value),
          do: {:illegal_field, unquote(atom_name), :not_a_string}

      # Fail if the value is an empty string (binary):
      def unquote(function_name)(%{unquote(json_name) => value})
          when byte_size(value) == 0,
          do: {:illegal_field, unquote(atom_name), :empty}

      # Return the value otherwise:
      def unquote(function_name)(%{unquote(json_name) => value}),
        do: {:ok, value}

      # In case the key is not present at all:
      unquote(fallback)

      # ---

      # When using the bang version, no validation is done:
      def unquote(bang_function_name)(%__MODULE__{unquote(atom_name) => value}),
        do: value

      # When using the bang version, no validation is done:
      def unquote(bang_function_name)(json_map),
        do: Map.get(json_map, unquote(json_name))
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro timestamp(json_name, var_name, opts \\ []) do
    atom_name = String.to_atom(var_name)
    function_name = atom_name
    bang_function_name = String.to_atom(var_name <> "!")

    required? = Keyword.get(opts, :required?, true)

    fallback =
      if required? do
        quote do
          def unquote(function_name)(_), do: {:illegal_field, unquote(atom_name), :missing}
        end
      else
        quote do
          def unquote(function_name)(_), do: {:ok, nil}
        end
      end

    quote do
      # If passed a struct no validation is done:
      def unquote(function_name)(%__MODULE__{unquote(atom_name) => value}),
        do: value

      # eventTime is expected to be a RFC3339-formatted string:
      def unquote(function_name)(%{unquote(json_name) => value}) do
        case Timex.parse(value, "{RFC3339}") do
          {:ok, datetime} -> {:ok, datetime}
          {:error, error} -> {:illegal_field, unquote(atom_name), error}
        end
      end

      # In case the key is not present at all:
      unquote(fallback)

      # ---

      # When using the bang version, no validation is done:
      def unquote(bang_function_name)(%__MODULE__{unquote(atom_name) => value}),
        do: value

      # When using the bang version, no validation is done:
      def unquote(bang_function_name)(json_map),
        do: Map.get(json_map, unquote(json_name))
    end
  end
end
