defmodule Rig.Subscription do
  @moduledoc false
  @typedoc """
  A subscription for a specific event type.

  The constraints are expected in [conjunctive normal
  form](https://en.wikipedia.org/wiki/Conjunctive_normal_form) and defined using a
  list of maps. For example:

  ```elixir
  %{
    event_type: "com.github.pull.create",
    constraints: [
      %{ "head_repo" => "octocat/Hello-World" },
      %{ "base_repo" => "octocat/Hello-World" }
    ]
  }
  ```

  """

  @type constraints :: [%{required(String.t()) => String.t()}]

  @type t :: %__MODULE__{
          event_type: String.t(),
          constraints: constraints
        }

  @derive Jason.Encoder
  @enforce_keys [:event_type]
  defstruct event_type: nil,
            constraints: []

  defimpl String.Chars do
    alias Rig.Subscription

    def to_string(%Subscription{} = sub) do
      "Subscription for #{sub.event_type} (#{inspect(sub.constraints)})"
    end
  end

  @spec new(map) :: t | {:error, any}
  def new(%{} = params) do
    params = %{
      event_type: event_type(params),
      constraints: constraints(params)
    }

    struct!(__MODULE__, params)
  rescue
    err -> {:error, err, params}
  end

  defp event_type(%{event_type: event_type}), do: event_type
  defp event_type(%{"event_type" => event_type}), do: event_type
  defp event_type(%{"eventType" => event_type}), do: event_type
  defp event_type(_), do: raise("event-type not found")

  defp constraints(%{constraints: constraints}), do: constraints
  defp constraints(%{"constraints" => constraints}), do: constraints
  defp constraints(%{one_of: constraints}), do: constraints
  defp constraints(%{"one_of" => constraints}), do: constraints
  defp constraints(%{"oneOf" => constraints}), do: constraints
  defp constraints(_), do: []
end
