defmodule RigInboundGateway.ExtractorConfig do
  @moduledoc false

  alias Rig.EventFilter

  @extractors System.get_env("EXTRACTORS")

  def set(config) when is_map(config) do
    System.put_env("EXTRACTORS", Jason.encode!(config))
    EventFilter.reload_config_everywhere()
  end

  def restore do
    System.put_env("EXTRACTORS", @extractors)
    EventFilter.reload_config_everywhere()
  end
end
