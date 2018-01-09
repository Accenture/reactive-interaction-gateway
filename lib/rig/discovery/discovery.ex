defmodule Rig.Discovery do
  @moduledoc """
  Module responsible to start Peerage application if relevant.
  Peerage will be auto-configured by values from environment variables.
  """

  use Rig.Config, [:discovery_type]
  require Logger

  def start do
    conf = config()
    use_discovery(conf.discovery_type)
  end

  defp use_discovery(nil) do
    Logger.info("No discovery for cluster specified")
  end

  defp use_discovery("dns") do
    conf = config()
    Application.put_env(:peerage, :via, Peerage.Via.Dns)
    Application.put_env(:peerage, :dns_name, conf.dns_name)
    set_default_opts()
    start_peerage()
    Logger.info("Using DNS as a discovery for cluster")
  end

  defp start_peerage do
    Peerage.start(nil, nil)
  end

  defp set_default_opts do
    Application.put_env(:peerage, :app_name, "rig")
    Application.put_env(:peerage, :interval, 5)
  end
end
