{:ok, _} = Application.ensure_all_started(:fake_server)

ExUnit.start()
# Exclude all smoke tests from running by default
ExUnit.configure(exclude: [smoke: true])
Application.ensure_all_started(:bypass)
