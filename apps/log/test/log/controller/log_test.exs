defmodule Helix.Log.Controller.LogTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Log.Controller.Log, as: Controller
  alias Helix.Log.Repo
  alias Helix.Log.Model.Log

  describe "log recovering" do
    test "removes the log if it was forged" do
      {:ok, log} = Controller.create(
        Random.pk(),
        Random.pk(),
        "What's going on",
        12)

      assert Repo.get_by(Log, log_id: log.log_id)
      Controller.recover(log)
      refute Repo.get_by(Log, log_id: log.log_id)
    end

    test "removes the last revision" do
      log =
        Random.pk()
        |> Controller.create!(Random.pk(), "I say hey hey hey", 50)
        |> Controller.revise!(Random.pk(), "I say hey", 10)
        |> Repo.preload(:revisions, force: true)

      assert 2 === Enum.count(log.revisions)

      Controller.recover(log)

      revisions =
        log
        |> Repo.preload(:revisions, force: true)
        |> Map.fetch!(:revisions)
        |> Enum.map(&(&1.forge_version))

      assert 50 === List.first(revisions)
    end
  end
end