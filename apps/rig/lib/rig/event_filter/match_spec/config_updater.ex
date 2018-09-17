defmodule Rig.EventFilter.MatchSpec.ConfigUpdater do
  @moduledoc false

  @n_non_constraint_fields 2

  @type match_spec :: list()

  @spec match_spec(non_neg_integer, non_neg_integer) :: match_spec
  def match_spec(n_cur_fields, n_new_fields) when n_new_fields > n_cur_fields do
    cur_tuple_size = @n_non_constraint_fields + n_cur_fields

    match_tuple_as_list = for i <- 1..cur_tuple_size, do: :"$#{i}"
    match_tuple = List.to_tuple(match_tuple_as_list)

    match_constraints = []

    match_body_as_list = match_tuple_as_list ++ List.duplicate(nil, n_new_fields - n_cur_fields)
    match_body = [{List.to_tuple(match_body_as_list)}]

    [{match_tuple, match_constraints, match_body}]
  end
end
