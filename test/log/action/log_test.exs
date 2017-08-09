defmodule Helix.Log.Action.LogTest do

  use Helix.Test.IntegrationCase

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Log.LogCreatedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo

  alias Helix.Test.Factory.Log, as: LogFactory

  describe "create/3" do
    test "succeeds with valid input" do
      server_id = Server.ID.generate()
      entity_id = Entity.ID.generate()
      message = "They are taking the hobbits to Isengard"

      assert {:ok, _, _} = LogAction.create(server_id, entity_id, message)
    end

    test "returns LogCreated event" do
      server_id = Server.ID.generate()
      entity_id = Entity.ID.generate()
      message = "Just as expected"

      result = LogAction.create(server_id, entity_id, message)
      assert {:ok, _, [%LogCreatedEvent{}]} = result
    end
  end

  describe "revise/4" do
    test "overrides log message" do
      log = LogFactory.insert(:log)
      entity = Entity.ID.generate()
      message = "É nois que voa, bruxão!"
      forge_version = Enum.random(1..999)

      assert {:ok, _, _} = LogAction.revise(log, entity, message, forge_version)
      assert %{message: ^message} = LogQuery.fetch(log.log_id)
    end

    test "returns LogModified event" do
      log = LogFactory.insert(:log)
      entity = Entity.ID.generate()
      message = "Don't dead, open inside"

      result = LogAction.revise(log, entity, message, 1)
      assert {:ok, _, [%LogModifiedEvent{}]} = result
    end
  end

  describe "recover/1" do
    test "recovers log to the last message" do
      log = LogFactory.insert(:log)
      entity = Entity.ID.generate()

      message0 = log.message
      message1 = "A monad is a monoid in the category of the endofunctors"
      message2 = "A commit a day keeps the PM away"

      LogAction.revise(log, entity, message1, 1)
      log = LogQuery.fetch(log.log_id)
      assert %{message: ^message1} = log

      LogAction.revise(log, entity, message2, 2)
      log = LogQuery.fetch(log.log_id)
      assert %{message: ^message2} = log

      assert {:ok, :recovered, _} = LogAction.recover(log)
      assert %{message: ^message1} = LogQuery.fetch(log.log_id)

      assert {:ok, :recovered, _} = LogAction.recover(log)
      assert %{message: ^message0} = LogQuery.fetch(log.log_id)
    end

    test "returns LogModified event when a message is recovered" do
      log = LogFactory.insert(:log)
      entity = Entity.ID.generate()
      message = "nullPointerException"

      LogAction.revise(log, entity, message, 1)

      assert {:ok, :recovered, [%LogModifiedEvent{}]} = LogAction.recover(log)
    end

    test "returns error when log is original" do
      log = LogFactory.insert(:log)

      assert {:error, :original_revision} == LogAction.recover(log)
    end

    test "deletes log if it was forged" do
      log = LogFactory.insert(:log, forge_version: 1)

      assert Repo.get(Log, log.log_id)
      assert {:ok, :deleted, _} = LogAction.recover(log)
      refute Repo.get(Log, log.log_id)
    end

    test "returns LogDeleted event when forged log is deleted" do
      log = LogFactory.insert(:log, forge_version: 1)

      assert {:ok, :deleted, [%LogDeletedEvent{}]} = LogAction.recover(log)
    end
  end
end
