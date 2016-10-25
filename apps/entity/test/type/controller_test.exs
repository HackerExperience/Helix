defmodule HELM.Entity.Type.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Type.Controller, as: EntityTypeCtrl

  setup do
    {:ok, id: HRand.random_numeric_string()}
  end

  describe "create/1" do
    test "success", %{id: id} do
      assert {:ok, _} = EntityTypeCtrl.create(id)
    end

    test "failure", %{id: id} do
      {:ok, _} = EntityTypeCtrl.create(id)
      assert_raise Ecto.ConstraintError, fn ->
        EntityTypeCtrl.create(id)
      end
    end
  end

  describe "find/1" do
    test "success", %{id: id} do
      {:ok, type} = EntityTypeCtrl.create(id)
      assert {:ok, type} = EntityTypeCtrl.find(type.entity_type)
    end

    test "failure" do
      assert {:error, :notfound} = EntityTypeCtrl.find("")
    end
  end

  test "delete/1 idempotency", %{id: id} do
    {:ok, type} = EntityTypeCtrl.create(id)
    assert :ok = EntityTypeCtrl.delete(type.entity_type)
    assert :ok == EntityTypeCtrl.delete(type.entity_type)
  end
end
