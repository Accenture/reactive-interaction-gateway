defmodule RigTests.AvroConfig do
  @moduledoc false

  @var_name "KAFKA_SERIALIZER"
  @orig_val System.get_env(@var_name)

  def set(val) do
    System.put_env(@var_name, val)
  end

  def restore do
    case @orig_val do
      nil -> System.delete_env(@var_name)
      _ -> System.put_env(@var_name, @orig_val)
    end
  end
end
