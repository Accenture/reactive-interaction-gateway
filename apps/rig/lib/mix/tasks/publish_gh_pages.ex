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

    IO.puts("Source URL: #{source_url}")

    docs_out_dir = new_empty_tmp_dir("rig_source_docs")
    Mix.Task.run("docs", ["--output", docs_out_dir])

    orig_ref =
      case git(["rev-parse", "--abbrev-ref", "HEAD"]) do
        "HEAD" ->
          # This is a detached checkout -> we use the commit sha:
          git(["rev-parse", "HEAD"])

        branch when byte_size(branch) > 0 ->
          branch
      end

    gh_pages_workdir = new_empty_tmp_dir("rig_gh-pages")
    git(["clone", "--single-branch", "--branch", "gh-pages", source_url, gh_pages_workdir])
    target_dir = Path.join(gh_pages_workdir, @target_dir)
    File.rm_rf!(target_dir)
    File.cp_r!(docs_out_dir, target_dir)
    git(["add", "."], cd: gh_pages_workdir)
    git(["commit", "-m", "Deploy source documentation"], cd: gh_pages_workdir)
    git(["push", "--verbose"], cd: gh_pages_workdir)

    # cleanup
    File.rm_rf(docs_out_dir)
    File.rm_rf(gh_pages_workdir)
  end

  defp new_empty_tmp_dir(dirname) do
    dir = System.tmp_dir!() |> Path.join(dirname)
    File.rm_rf!(dir)
    File.mkdir!(dir)
    dir
  end

  defp git(args, opts \\ []) do
    {stdout, 0} = System.cmd("git", args, opts)
    stdout |> String.trim()
  end
end
