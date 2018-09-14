defmodule Rig.EventFilter.FilterConfig do
  @type jwt_config :: %{
          json_pointer: String.t()
        }

  @type event_config :: %{
          json_pointer: String.t()
        }

  @type field_config :: %{
          stable_field_index: non_neg_integer,
          jwt: jwt_config | nil,
          event: event_config
        }

  @type field_name :: atom

  @type t :: %{
          optional(field_name) => field_config
        }
end
