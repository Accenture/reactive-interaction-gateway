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
  defmodule ValidationError do
    defexception [:error, :params]

    def message(%__MODULE__{error: error, params: params}),
      do: "invalid subscription: #{error} when parsing #{inspect(params)}"
  end

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

  # ---

  @spec new(any) :: {:ok, t} | {:error, %ValidationError{}}
  def new(%{} = params) do
    params = %{
      event_type: event_type(params),
      constraints: constraints(params)
    }

    subscription = struct!(__MODULE__, params)
    validate(subscription)
    {:ok, subscription}
  catch
    {:error, reason} when byte_size(reason) > 0 ->
      {:error, %ValidationError{error: reason, params: params}}
  end

  def new(params), do: {:error, %ValidationError{error: "not a map", params: params}}

  # ---

  @spec new!(any) :: t
  def new!(params) do
    case new(params) do
      {:ok, sub} -> sub
      {:error, err} -> raise err
    end
  end

  # ---

  defp event_type(%{event_type: event_type}), do: event_type
  defp event_type(%{"event_type" => event_type}), do: event_type
  defp event_type(%{"eventType" => event_type}), do: event_type
  defp event_type(_), do: throw({:error, "event-type not found"})

  defp constraints(%{constraints: constraints}), do: constraints
  defp constraints(%{"constraints" => constraints}), do: constraints
  defp constraints(%{one_of: constraints}), do: constraints
  defp constraints(%{"one_of" => constraints}), do: constraints
  defp constraints(%{"oneOf" => constraints}), do: constraints
  defp constraints(_), do: []

  # ---

  defp validate(%__MODULE__{event_type: event_type, constraints: constraints}) do
    validate_event_type(event_type)
    validate_constraints(constraints)
  end

  # ---

  defp validate_event_type(type) when byte_size(type) > 0, do: :ok
  defp validate_event_type(_), do: throw({:error, "event-type empty"})

  # ---

  defp validate_constraints(constraints) when is_list(constraints) do
    Enum.each(constraints, &validate_constraint/1)
  end

  defp validate_constraints(_),
    do: throw({:error, "constraints expected to be a list of disjunctive clauses"})

  # ---

  defp validate_constraint(conjunction) when not is_map(conjunction),
    do: throw({:error, "a disjunctive clause expected to be a conjunction represented by a map"})

  defp validate_constraint(conjunction) do
    if not Enum.all?(conjunction, fn {k, _} -> is_nonempty_string(k) end) do
      throw({:error, "conjunctive clauses expected to be a map with nonempty strings as keys"})
    end
  end

  # ---

  defp is_nonempty_string(s) when byte_size(s) > 0, do: true
  defp is_nonempty_string(_), do: false
end
