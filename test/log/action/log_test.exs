defmodule Helix.Log.Action.LogTest do

  use Helix.Test.Case.Integration

  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Model.Log
  alias Helix.Log.Event.Log.Created, as: LogCreatedEvent
  alias Helix.Log.Event.Log.Deleted, as: LogDeletedEvent
  alias Helix.Log.Event.Log.Modified, as: LogModifiedEvent
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo

  alias Helix.Test.Log.Factory, as: LogFactory

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  describe "create/3" do
    test "succeeds with valid input" do
      server_id = ServerHelper.id()
      entity_id = EntityHelper.id()
      message = "They are taking the hobbits to Isengard"

      assert {:ok, _, _} = LogAction.create(server_id, entity_id, message)
    end

    test "returns LogCreated event" do
      server_id = ServerHelper.id()
      entity_id = EntityHelper.id()
      message = "Just as expected"

      result = LogAction.create(server_id, entity_id, message)
      assert {:ok, _, [%LogCreatedEvent{}]} = result
    end
  end

  describe "revise/4" do
    test "overrides log message" do
      log = LogFactory.insert(:log)
      entity = EntityHelper.id()
      message = "É nois que voa, bruxão!"
      forge_version = Enum.random(1..999)

      assert {:ok, _, _} = LogAction.revise(log, entity, message, forge_version)
      assert %{message: ^message} = LogQuery.fetch(log.log_id)
    end

    test "returns LogModified event" do
      log = LogFactory.insert(:log)
      entity = EntityHelper.id()
      message = "Don't dead, open inside"

      result = LogAction.revise(log, entity, message, 1)
      assert {:ok, _, [%LogModifiedEvent{}]} = result
    end
  end

  describe "recover/1" do
    test "recovers log to the last message" do
      log = LogFactory.insert(:log)
      entity = EntityHelper.id()

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
      entity = EntityHelper.id()
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
