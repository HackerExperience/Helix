defmodule HELM.Entity.Controller.EntityTypesTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Controller.EntityTypes, as: CtrlEntityTypes

  setup do
    {:ok, id: HRand.random_numeric_string()}
  end

  describe "create/1" do
    test "success", %{id: id} do
      assert {:ok, _} = CtrlEntityTypes.create(id)
    end

    test "failure", %{id: id} do
      {:ok, _} = CtrlEntityTypes.create(id)
      assert_raise Ecto.ConstraintError, fn ->
        CtrlEntityTypes.create(id)
      end
    end
  end

  describe "find/1" do
    test "success", %{id: id} do
      {:ok, type} = CtrlEntityTypes.create(id)
      assert {:ok, type} = CtrlEntityTypes.find(type.entity_type)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlEntityTypes.find("")
    end
  end

  test "delete/1 idempotency", %{id: id} do
    {:ok, type} = CtrlEntityTypes.create(id)
    assert :ok = CtrlEntityTypes.delete(type.entity_type)
    assert :ok == CtrlEntityTypes.delete(type.entity_type)
  end
end