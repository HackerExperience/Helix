defmodule Helix.Log.Action.LogTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo

  alias Helix.Test.Factory.Log, as: Factory

  describe "create/3" do
    test "succeeds with valid input" do
      server_id = Random.pk()
      entity_id = Random.pk()
      message = "They are taking the hobbits to Isengard"

      result = LogAction.create(server_id, entity_id, message)

      assert {:ok, _} = result
      assert {:ok, %{log: %Log{}, events: events}} = result
      assert Enum.all?(events, &Map.has_key?(&1, :__struct__))
    end
  end

  describe "revise/4" do
    test "overrides log message" do
      log = Factory.insert(:log)
      entity = Random.pk()
      message = "É nois que voa, bruxão!"
      forge_version = Enum.random(1..999)

      result = LogAction.revise(log, entity, message, forge_version)

      assert {:ok, %{events: events}} = result
      assert Enum.all?(events, &Map.has_key?(&1, :__struct__))
      assert %{message: ^message} = LogQuery.fetch(log.log_id)
    end
  end

  describe "recover/1" do
    test "recovers log to the last message" do
      log = Factory.insert(:log)
      entity = Random.pk()

      message0 = log.message
      message1 = "A monad is a monoid in the category of the endofunctors"
      message2 = "A commit a day keeps the PM away"

      LogAction.revise(log, entity, message1, 1)
      log = LogQuery.fetch(log.log_id)
      assert %{message: ^message1} = log

      LogAction.revise(log, entity, message2, 2)
      log = LogQuery.fetch(log.log_id)
      assert %{message: ^message2} = log

      {:ok, _} = LogAction.recover(log)
      assert %{message: ^message1} = LogQuery.fetch(log.log_id)

      {:ok, _} = LogAction.recover(log)
      assert %{message: ^message0} = LogQuery.fetch(log.log_id)
    end

    test "returns LogModified event when a message is recovered" do
      log = Factory.insert(:log)
      entity = Random.pk()
      message = "nullPointerException"

      LogAction.revise(log, entity, message, 1)

      assert {:ok, %{events: [%LogModifiedEvent{}]}} = LogAction.recover(log)
    end

    test "returns error when log is original" do
      log = Factory.insert(:log)

      # This is an Ecto Multi return; it means that the operation failed on
      # operation "log", returning "original_revision" and that the success
      # state is the map (empty because nothing else was done)
      assert {:error, :log, :original_revision, %{}} == LogAction.recover(log)
    end

    test "deletes log if it was forged" do
      log = Factory.insert(:log, forge_version: 1)

      assert Repo.get(Log, log.log_id)
      assert {:ok, _} = LogAction.recover(log)
      refute Repo.get(Log, log.log_id)
    end

    test "returns LogDeleted event when forged log is deleted" do
      log = Factory.insert(:log, forge_version: 1)

      assert {:ok, %{events: [%LogDeletedEvent{}]}} = LogAction.recover(log)
    end
  end
end
