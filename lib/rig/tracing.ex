defmodule RIG.Tracing do
  use Rig.Config, [:jaeger_host, :jaeger_port, :jaeger_service_name]

  def start do
    conf = config()
    Application.put_env(:opencensus, :reporters, reporters(conf), :persistent)
    Application.ensure_all_started(:opencensus, :permanent)
  end

  # ---

  defp reporters(%{jaeger_host: ''}), do: []

  defp reporters(conf),
    do: [
      {
        :oc_reporter_jaeger,
        [
          {:hostname, conf.jaeger_host},
          {:port, conf.jaeger_port},
          {:service_name, conf.jaeger_service_name}
        ]
      }
    ]
end
