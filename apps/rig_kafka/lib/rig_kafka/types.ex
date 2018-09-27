defmodule RigKafka.Types do
  @type client_name :: atom

  @type host :: String.t()
  @type port_num :: pos_integer()
  @type broker :: {host, port_num}
  @type brokers :: [broker]

  @type topic :: String.t()
  @type topics :: [topic]

  @type partition :: non_neg_integer()
end
