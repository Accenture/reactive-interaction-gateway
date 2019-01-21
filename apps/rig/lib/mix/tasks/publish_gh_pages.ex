defmodule Mix.Tasks.PublishGhPages do
  @moduledoc """
  Publishes the API reference documentation (mix docs) to the gh-pages branch.

  Fails if the branch doesn't exist.
  """

  use Mix.Task
  require Logger

  @target_branch "gh-pages"
  @target_dir "source_docs"

  @shortdoc "Publishes the output of mix docs to the gh-pages branch."
  @impl true
  def run(_) do
    {:ok, git_user} =
      with git_user when byte_size(git_user) > 0 <- System.get_env("GIT_USER"),
           do: {:ok, git_user}

    source_url =
      Rig.Umbrella.Mixfile.project()[:source_url]
      |> URI.parse()
      |> Map.put(:userinfo, git_user)
      |> URI.to_string()

    docs_out_dir = System.tmp_dir!() |> Path.join("rig_source_docs")
    File.rm_rf!(docs_out_dir)
    File.mkdir!(docs_out_dir)
    Mix.Task.run("docs", ["--output", docs_out_dir])

    orig_ref =
      case git(["rev-parse", "--abbrev-ref", "HEAD"]) do
        "HEAD" ->
          # This is a detached checkout -> we use the commit sha:
          git(["rev-parse", "HEAD"])

        branch when byte_size(branch) > 0 ->
          branch
      end

    IO.inspect(git(["branch", "-a"]), label: "git branch -a")
    git(["checkout", "origin/#{@target_branch}"])
    File.rm_rf!(@target_dir)
    File.cp_r!(docs_out_dir, @target_dir)
    git(["add", @target_dir])
    git(["commit", "-m", "Deploy source documentation"])
    git(["push", "--verbose", source_url, "HEAD:#{@target_branch}"])

    # cleanup
    File.rm_rf(docs_out_dir)
    git(["checkout", orig_ref])
  end

  defp git(args) do
    {stdout, 0} = System.cmd("git", args)
    stdout |> String.trim()
  end
end
