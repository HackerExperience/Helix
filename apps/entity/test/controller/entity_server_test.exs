defmodule Helix.Entity.Controller.EntityServerTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Entity.Repo
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityType
  alias Helix.Entity.Controller.EntityServer, as: CtrlEntityServer

  setup_all do
    # FIXME
    type = case Repo.all(EntityType) do
      [] ->
        %{entity_type: Burette.Color.name()}
        |> EntityType.create_changeset()
        |> Repo.insert!()
      et = [_|_] ->
        Enum.random(et)
    end

    [entity_type: type]
  end

  setup context do
    entity =
      %{
        entity_type: context.entity_type.entity_type,
        reference_id: Random.pk()}
      |> Entity.create_changeset()
      |> Repo.insert!()

    {:ok, entity: entity}
  end

  test "create/1", %{entity: entity} do
    server_id = Random.pk()

    assert {:ok, _} = CtrlEntityServer.create(entity.entity_id, server_id)
  end

  describe "find/1" do
    test "fetching linked servers", %{entity: entity} do
      servers = [Random.pk(), Random.pk(), Random.pk()]

      Enum.each(servers, &CtrlEntityServer.create(entity.entity_id, &1))

      found_servers =
        entity.entity_id
        |> CtrlEntityServer.find()
        |> Enum.map(&to_string(&1.server_id))
        |> Enum.sort()

      assert Enum.sort(servers) === found_servers
    end

    test "returns empty list if entity has no server", %{entity: entity} do
      assert [] === CtrlEntityServer.find(entity.entity_id)
    end
  end

  test "delete is idempotent", %{entity: entity} do
    server_id = HELL.TestHelper.Random.pk()
    CtrlEntityServer.create(entity.entity_id, server_id)

    refute [] == CtrlEntityServer.find(entity.entity_id)
    CtrlEntityServer.delete(entity.entity_id, server_id)
    CtrlEntityServer.delete(entity.entity_id, server_id)
    assert [] == CtrlEntityServer.find(entity.entity_id)
  end
end