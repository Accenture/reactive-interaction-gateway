defmodule Mix.Tasks.SmokeTest do
  @moduledoc """
  Runs the smoke test.
  """

  use Mix.Task
  require Logger

  @shortdoc "Runs the smoke test."
  def run(_) do
    Application.ensure_all_started(:porcelain)

    prog = "docker-compose"

    args = [
      "-f",
      "smoke_tests.docker-compose.yml",
      "up",
      "--build",
      "--abort-on-container-exit"
    ]

    stream = IO.binstream(:stdio, :line)

    %Porcelain.Result{status: 0} =
      Porcelain.exec(prog, args, out: stream, err: :out, dir: "smoke_tests")
  end
end
