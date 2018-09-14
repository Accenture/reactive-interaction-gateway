defmodule Rig.EventFilter.Server.SubscriberMatchSpec do
  @moduledoc false

  @type sorted_fields :: list(atom)
  @type value_func :: (atom -> String.t())

  @spec match_spec(sorted_fields, value_func) :: list
  def match_spec(fields, get_value_in_event) do
    n_fields = length(fields)

    [
      {
        match_head(n_fields),
        match_conditions(fields, get_value_in_event),
        match_body()
      }
    ]
  end

  def match_head(n_fields) do
    pid_field = :"$1"
    ignored_expiration_ts_field = :_
    field_no_seq = Stream.iterate(2, &(&1 + 1))

    ([pid_field, ignored_expiration_ts_field] ++
       (field_no_seq
        |> Stream.map(&:"$#{&1}")
        |> Enum.take(n_fields)))
    |> List.to_tuple()
  end

  def match_conditions(fields, get_value_in_event)
  def match_conditions([], _), do: []

  def match_conditions(fields, get_value_in_event) do
    {_, conditions} =
      Enum.reduce(fields, {2, nil}, fn field, {idx, acc} ->
        match_field = :"$#{idx}"

        clause =
          case get_value_in_event.(field) do
            nil ->
              {:==, match_field, nil}

            value ->
              {
                :orelse,
                {:==, match_field, nil},
                {:==, match_field, value}
              }
          end

        condition =
          if is_nil(acc) do
            clause
          else
            {
              :andalso,
              acc,
              clause
            }
          end

        {idx + 1, condition}
      end)

    [conditions]
  end

  def match_body do
    # The result is a list of connection PIDs (= first value of each row):
    [:"$1"]
  end
end
