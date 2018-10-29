Application.put_env(:rig, RigApi.ApisController,
  rig_proxy: RigInboundGateway.Proxy,
  persistent: true
)

{:ok, _} = Application.ensure_all_started(:fake_server)
ExUnit.start()
ExUnit.configure(capture_log: true)

# case Mix.env() do
#   :prod ->
#     {:ok, _} = Application.ensure_all_started(:fake_server)
#     ExUnit.configure(capture_log: true)
#
#   env ->
#     IO.puts("System tests only run with :prod env (env=#{env}).")
#     # Don't run any tests:
#     ExUnit.configure(only_test_ids: MapSet.new())
# end
