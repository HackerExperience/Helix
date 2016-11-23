defmodule HELM.Entity.Controller.EntityTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6
  alias HELM.Entity.Repo
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Entity.Controller.Entity, as: CtrlEntity
  alias HELM.Entity.Model.EntityType, as: MdlEntityType

  @entity_type HRand.string(min: 20)

  setup_all do
    %{entity_type: @entity_type}
    |> MdlEntityType.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    reference_id = IPv6.generate([])
    payload = %{entity_type: @entity_type, reference_id: reference_id}
    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlEntity.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, enty} = CtrlEntity.create(payload)
      assert {:ok, ^enty} = CtrlEntity.find(enty.entity_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlEntity.find(IPv6.generate([]))
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    {:ok, enty} = CtrlEntity.create(payload)
    assert :ok = CtrlEntity.delete(enty.entity_id)
    assert :ok = CtrlEntity.delete(enty.entity_id)
    assert {:error, :notfound} = CtrlEntity.find(enty.entity_id)
  end
end