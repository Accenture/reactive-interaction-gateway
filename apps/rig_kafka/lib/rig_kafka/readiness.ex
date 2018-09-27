# defmodule RigKafka.Readiness do
#   @moduledoc false

#   alias RigKafka.Types

#   alias RigKafka.ClientId

#   @check_delay_ms 1_000

#   @spec ready?(pid, Types.topic(), Types.partition(), Types.integer()) :: boolean

#   def ready?(_, _, _, timeout) when timeout < 0, do: false

#   def ready?(pid, topic, partition, timeout_ms) do
#     brod_client_id = ClientId.from_name(client_name)

#     connected? =
#       case :brod.get_consumer(brod_client_id, topic, partition) do
#         {:ok, _pid} -> true
#         _ -> false
#       end

#     if connected? do
#       true
#     else
#       retry_delay_ms = if timeout_ms >= @check_delay_ms, do: @check_delay_ms, else: timeout_ms

#       if retry_delay_ms <= 0 do
#         false
#       else
#         :timer.sleep(retry_delay_ms)
#         ready?(client_name, topic, partition, timeout_ms - retry_delay_ms)
#       end
#     end
#   end
# end
