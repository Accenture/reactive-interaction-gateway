defmodule RigInboundGateway.ExtractorConfig do
  @moduledoc false

  alias Rig.EventFilter

  @var_name "EXTRACTORS"
  @orig_val System.get_env(@var_name)

  def set(config) when is_map(config) do
    System.put_env(@var_name, Jason.encode!(config))
    EventFilter.reload_config_everywhere()
  end

  def restore do
    case @orig_val do
      nil -> System.delete_env(@var_name)
      _ -> System.put_env(@var_name, @orig_val)
    end

    EventFilter.reload_config_everywhere()
  end
end
