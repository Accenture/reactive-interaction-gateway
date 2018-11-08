defmodule RigKafka.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    [
      name: RigKafka.DynamicSupervisor,
      strategy: :one_for_one
    ]
    |> DynamicSupervisor.start_link()
  end
end
