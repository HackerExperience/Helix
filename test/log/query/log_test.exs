defmodule Helix.Log.Query.LogTest do

  use Helix.Test.Case.Integration

  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Log.Factory, as: Factory

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  describe "get_logs_on_server/1" do
    # Well, i think that the function name might be a bit obvious, eh ?
    test "returns logs that belongs to a server" do
      # Random logs on other servers
      Enum.each(1..5, fn _ -> Factory.insert(:log) end)

      server = ServerHelper.id()
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

  describe "get_logs_from_entity_on_server/2" do
    test "returns logs that were created by the entity" do
      server = ServerHelper.id()
      entity = EntityHelper.id()

      create_log = fn params ->
        defaults = %{
          server_id: ServerHelper.id(),
          entity_id: EntityHelper.id(),
          message: "Default message"
        }
        p = Map.merge(defaults, params)

        {:ok, log, _} = LogAction.create(p.server_id, p.entity_id, p.message)
        log
      end

      # Random logs that were not created by the entity
      Enum.each(1..5, fn _ -> create_log.(%{server_id: server}) end)

      entity_params = %{server_id: server, entity_id: entity}
      expected =
        1..5
        |> Enum.map(fn _ -> create_log.(entity_params) end)
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
      server = ServerHelper.id()
      entity = EntityHelper.id()

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
