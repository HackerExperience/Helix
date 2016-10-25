defmodule HELM.Entity.Type.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Type.Controller, as: EntityTypeCtrl

  setup do
    {:ok, id: HRand.random_numeric_string()}
  end

  describe "create/1" do
    test "success", data do
      assert {:ok, _} = EntityTypeCtrl.create(data.id)
    end

    test "failure", data do
      {:ok, _} = EntityTypeCtrl.create(data.id)
      assert_raise Ecto.ConstraintError, fn ->
        EntityTypeCtrl.create(data.id)
      end
    end
  end

  describe "find/1" do
    test "success", data do
      {:ok, type} = EntityTypeCtrl.create(data.id)
      assert {:ok, type} =
        EntityTypeCtrl.find(type.entity_type)
    end

    test "failure" do
      assert {:error, :notfound} = EntityTypeCtrl.find("")
    end
  end

  describe "delete/1" do
    test "success", data do
      {:ok, type} = EntityTypeCtrl.create(data.id)
      assert {:ok, _} =
        EntityTypeCtrl.delete(type.entity_type)
    end

    test "failure", data do
      {:ok, type} = EntityTypeCtrl.create(data.id)
      {:ok, _} = EntityTypeCtrl.delete(type.entity_type)
      assert {:error, :notfound} =
        EntityTypeCtrl.delete(type.entity_type)
    end
  end
end
