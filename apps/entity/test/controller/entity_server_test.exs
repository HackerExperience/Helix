defmodule HELM.Entity.Controller.EntityServerTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6
  alias HELM.Entity.Repo
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Entity.Controller.Entity, as: CtrlEntity
  alias HELM.Entity.Model.EntityType, as: MdlEntityType
  alias HELM.Entity.Controller.EntityServer, as: CtrlEntityServer

  @entity_type HRand.string(min: 20)

  setup_all do
    %{entity_type: @entity_type}
    |> MdlEntityType.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    reference_id = IPv6.generate([])
    server_id = IPv6.generate([])

    payload = %{entity_type: @entity_type, reference_id: reference_id}
    {:ok, payload: payload, server_id: server_id}
  end

  test "create/1", %{payload: payload, server_id: server_id} do
    {:ok, entity} = CtrlEntity.create(payload)
    assert {:ok, _} = CtrlEntityServer.create(entity.entity_id, server_id)
  end

  describe "find/1" do
    test "found servers", %{payload: payload, server_id: server_id} do
      {:ok, entity} = CtrlEntity.create(payload)
      {:ok, entry1} = CtrlEntityServer.create(entity.entity_id, server_id)
      {:ok, entry2} = CtrlEntityServer.create(entity.entity_id, IPv6.generate([]))
      assert Enum.sort([entry1, entry2]) == Enum.sort(CtrlEntityServer.find(entity.entity_id))
    end

    test "no servers found" do
      assert [] == CtrlEntityServer.find(IPv6.generate([]))
    end
  end

  test "delete/1 idempotency", %{payload: payload, server_id: server_id} do
    {:ok, entity} = CtrlEntity.create(payload)
    {:ok, _} = CtrlEntityServer.create(entity.entity_id, server_id)
    assert :ok = CtrlEntityServer.delete(entity.entity_id, server_id)
    assert :ok = CtrlEntityServer.delete(entity.entity_id, server_id)
    assert [] == CtrlEntityServer.find(entity.entity_id)
  end
end