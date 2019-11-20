defmodule Mix.Tasks.CompileKinesisClient do
  @moduledoc """
  Compiles the Java-based Kinesis client.
  """

  use Mix.Task
  require Logger

  @shortdoc "Compiles the Java-based Kinesis client."
  def run(_) do
    Application.ensure_all_started(:porcelain)

    stream = IO.binstream(:stdio, :line)

    case Porcelain.exec("mvn", ["package"], out: stream, err: :out, dir: "kinesis-client") do
      %Porcelain.Result{status: 0} -> Logger.info("kinesis-client jar successfully compiled.")
      %Porcelain.Result{status: s} -> Logger.warn("kinesis-client jar failed to build (status #{s}).")
    end
  end

end
