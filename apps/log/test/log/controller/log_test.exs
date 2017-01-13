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

      revision =
        log
        |> Repo.preload(:revisions)
        |> Map.fetch!(:revisions)
        |> List.first()

      Controller.recover(log, revision.revision_id)

      refute Repo.get_by(Log, log_id: log.log_id)
    end
  end
end