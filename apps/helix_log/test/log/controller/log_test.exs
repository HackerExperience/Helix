defmodule Helix.Log.Controller.LogTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Log.Controller.Log, as: Controller
  alias Helix.Log.Repo
  alias Helix.Log.Model.Log

  @moduletag :integration

  # FIXME: this is bad, create a factory and remove this
  defp create_log(params \\ []) do
    params = :maps.from_list(params)

    defaults = %{
      server_id: Random.pk(),
      entity_id: Random.pk(),
      message: "What's going on",
      forge_version: Random.number(12..24),
      crypto_version: Random.number(1..99)
    }

    defaults
    |> Map.merge(params)
    |> Log.create_changeset()
    |> Repo.insert!()

  end

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

    test "fails when the only revision is the original" do
      {:ok, log} = Controller.create(Random.pk(), Random.pk(), "???")

      assert Repo.get_by(Log, log_id: log.log_id)

      revision =
        log
        |> Repo.preload(:revisions)
        |> Map.fetch!(:revisions)
        |> List.first()

      refute revision.forge_version

      assert {:error, :raw} === Controller.recover(log, revision.revision_id)
    end
  end

  describe "fetching" do
    test "succeeds when log exists" do
      log = create_log()
      assert %Log{} = Controller.fetch(log.log_id)
    end

    test "fails when log doesn't exist" do
      refute Controller.fetch(Random.pk())
    end
  end

  describe "finding" do
    test "by server_id" do
      log = create_log()
      [got] = Controller.find(server_id: log.server_id)

      assert log.log_id == got.log_id
    end

    test "by message" do
      log = create_log(message: Random.string(min: 20))
      [got] = Controller.find(message: log.message)

      assert log.log_id == got.log_id
    end

    test "returns empty list when no log with server_id exists" do
      result = Controller.find(server_id: Random.pk())
      assert Enum.empty?(result)
    end

    test "returns empty list when no log with message exists" do
      result = Controller.find(message: Random.string(min: 20))
      assert Enum.empty?(result)
    end
  end
end
