defmodule HELM.Entity.Controller.EntityTypeTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Controller.EntityType, as: CtrlEntityType

  setup do
    {:ok, id: HRand.random_numeric_string()}
  end

  describe "create/1" do
    test "success", %{id: id} do
      assert {:ok, _} = CtrlEntityType.create(id)
    end

    test "failure", %{id: id} do
      {:ok, _} = CtrlEntityType.create(id)
      assert_raise Ecto.ConstraintError, fn ->
        CtrlEntityType.create(id)
      end
    end
  end

  describe "find/1" do
    test "success", %{id: id} do
      {:ok, type} = CtrlEntityType.create(id)
      assert {:ok, ^type} = CtrlEntityType.find(type.entity_type)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlEntityType.find("")
    end
  end

  test "delete/1 idempotency", %{id: id} do
    {:ok, type} = CtrlEntityType.create(id)
    assert :ok = CtrlEntityType.delete(type.entity_type)
    assert :ok == CtrlEntityType.delete(type.entity_type)
  end
end