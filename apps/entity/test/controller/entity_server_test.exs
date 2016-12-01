defmodule HELM.Entity.Controller.EntityServerTest do

  use ExUnit.Case, async: true

  alias HELM.Entity.Repo
  alias HELM.Entity.Model.Entity
  alias HELM.Entity.Model.EntityType
  alias HELM.Entity.Controller.EntityServer, as: CtrlEntityServer

  setup_all do
    # FIXME
    type = case Repo.all(EntityType) do
      [] ->
        %{entity_type: Burette.Color.name()}
        |> EntityType.create_changeset()
        |> Repo.insert!()
      [entity_type| _] ->
        entity_type
    end

    [entity_type: type]
  end

  setup context do
    entity =
      %{
        entity_type: context.entity_type.entity_type,
        reference_id: HELL.TestHelper.Random.pk()}
      |> Entity.create_changeset()
      |> Repo.insert!()

    {:ok, entity: entity}
  end

  test "create/1", %{entity: entity} do
    server_id = HELL.TestHelper.Random.pk()

    assert {:ok, _} = CtrlEntityServer.create(entity.entity_id, server_id)
  end

  describe "find/1" do
    test "fetching linked servers", %{entity: entity} do
      servers = [
        HELL.TestHelper.Random.pk(),
        HELL.TestHelper.Random.pk(),
        HELL.TestHelper.Random.pk()
      ]

      Enum.each(servers, &CtrlEntityServer.create(entity.entity_id, &1))

      found_servers =
        entity.entity_id
        |> CtrlEntityServer.find()
        |> Enum.map(&(&1 |> Map.get(:server_id) |> to_string()))
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
    assert CtrlEntityServer.delete(entity.entity_id, server_id)
    assert CtrlEntityServer.delete(entity.entity_id, server_id)
    assert [] == CtrlEntityServer.find(entity.entity_id)
  end
end