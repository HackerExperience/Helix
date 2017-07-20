defmodule Helix.Log.Query.LogTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Factory.Log, as: Factory

  describe "get_logs_on_server/2" do
    # Well, i think that the function name might be a bit obvious, eh ?
    test "returns logs that belongs to a server" do
      # Random logs on other servers
      Enum.each(1..5, fn _ -> Factory.insert(:log) end)

      server = Random.pk()
      expected =
        Enum.map(1..5, fn _ ->
          Factory.insert(:log, server_id: server)
        end)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      fetched =
        server
        |> LogQuery.get_logs_on_server()
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
        params = Map.merge(Factory.params_for(:log), params)
        {:ok, %{log: log}} = LogAction.create(
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
        |> LogQuery.get_logs_from_entity_on_server(entity)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      assert MapSet.equal?(expected, fetched)
    end

    test "returns logs that were touched by entity" do
      server = Random.pk()
      entity = Random.pk()

      # Random logs that were not touched by the entity
      Enum.each(1..5, fn _ ->
        Factory.insert(:log, server_id: server)
      end)

      expected =
        Enum.map(1..5, fn _ ->
          Factory.insert(:log, server_id: server)
        end)
        |> Enum.map(fn log ->
          LogAction.revise(log, entity, "touched", 1)
          log
        end)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      fetched =
        server
        |> LogQuery.get_logs_from_entity_on_server(entity)
        |> Enum.map(&(&1.log_id))
        |> MapSet.new()

      assert MapSet.equal?(expected, fetched)
    end
  end
end
