defmodule Helix.Log.Service.API.LogTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Test.Factory.Log, as: LogFactory
  alias Helix.Log.Service.API.Log, as: API
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent
  alias Helix.Log.Repo

  describe "create/3" do
    test "succeeds with valid input" do
      server_id = Random.pk()
      entity_id = Random.pk()
      message = "They are taking the hobbits to Isengard"

      result = API.create(server_id, entity_id, message)

      assert {:ok, _} = result
      assert {:ok, %{log: %Log{}, events: events}} = result
      assert Enum.all?(events, &Map.has_key?(&1, :__struct__))
    end
  end

  describe "revise/4" do
    test "overrides log message" do
      log = LogFactory.insert(:log)
      entity = Random.pk()
      message = "É nois que voa, bruxão!"
      forge_version = Enum.random(1..999)

      result = API.revise(log, entity, message, forge_version)

      assert {:ok, %{events: events}} = result
      assert Enum.all?(events, &Map.has_key?(&1, :__struct__))
      assert %{message: ^message} = API.fetch(log.log_id)
    end
  end

  describe "recover/1" do
    test "recovers log to the last message" do
      log = LogFactory.insert(:log)
      entity = Random.pk()

      message0 = log.message
      message1 = "A monad is a monoid in the category of the endofunctors"
      message2 = "A commit a day keeps the PM away"

      API.revise(log, entity, message1, 1)
      log = API.fetch(log.log_id)
      assert %{message: ^message1} = log

      API.revise(log, entity, message2, 2)
      log = API.fetch(log.log_id)
      assert %{message: ^message2} = log

      {:ok, _} = API.recover(log)
      assert %{message: ^message1} = API.fetch(log.log_id)

      {:ok, _} = API.recover(log)
      assert %{message: ^message0} = API.fetch(log.log_id)
    end

    test "returns LogModified event when a message is recovered" do
      log = LogFactory.insert(:log)
      entity = Random.pk()
      message = "nullPointerException"

      API.revise(log, entity, message, 1)

      assert {:ok, %{events: [%LogModifiedEvent{}]}} = API.recover(log)
    end

    test "returns error when log is original" do
      log = LogFactory.insert(:log)

      # This is an Ecto Multi return; it means that the operation failed on
      # operation "log", returning "original_revision" and that the success
      # state is the map (empty because nothing else was done)
      assert {:error, :log, :original_revision, %{}} == API.recover(log)
    end

    test "deletes log if it was forged" do
      log = LogFactory.insert(:log, forge_version: 1)

      assert Repo.get(Log, log.log_id)
      assert {:ok, _} = API.recover(log)
      refute Repo.get(Log, log.log_id)
    end

    test "returns LogDeleted event when forged log is deleted" do
      log = LogFactory.insert(:log, forge_version: 1)

      assert {:ok, %{events: [%LogDeletedEvent{}]}} = API.recover(log)
    end
  end

  describe "get_logs_on_server/2" do
    # Well, i think that the function name might be a bit obvious, eh ?
    test "returns logs that belongs to a server" do
      # Random logs on other servers
      Enum.each(1..5, fn _ -> LogFactory.insert(:log) end)

      server = Random.pk()
      expected =
        Enum.map(1..5, fn _ ->
          LogFactory.insert(:log, server_id: server)
        end)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      fetched =
        server
        |> API.get_logs_on_server()
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      assert MapSet.equal?(expected, fetched)
    end
  end

  describe "get_logs_from_entity_on_server/3" do
    test "returns logs that were created by the entity" do
      server = Random.pk()
      entity = Random.pk()

      create_log = fn params ->
        # FIXME
        params = Map.merge(LogFactory.params_for(:log), params)
        {:ok, %{log: log}} = API.create(
          params.server_id,
          params.entity_id,
          params.message)

        log
      end

      # Random logs that were not created by the entity
      Enum.each(1..5, fn _ ->
        create_log.(%{server_id: server})
      end)

      expected =
        Enum.map(1..5, fn _ ->
          create_log.(%{server_id: server, entity_id: entity})
        end)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      fetched =
        server
        |> API.get_logs_from_entity_on_server(entity)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      assert MapSet.equal?(expected, fetched)
    end

    test "returns logs that were touched by entity" do
      server = Random.pk()
      entity = Random.pk()

      # Random logs that were not touched by the entity
      Enum.each(1..5, fn _ ->
        LogFactory.insert(:log, server_id: server)
      end)

      expected =
        Enum.map(1..5, fn _ ->
          LogFactory.insert(:log, server_id: server)
        end)
        |> Enum.map(fn log ->
          API.revise(log, entity, "touched", 1)
          log
        end)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      fetched =
        server
        |> API.get_logs_from_entity_on_server(entity)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      assert MapSet.equal?(expected, fetched)
    end
  end
end
