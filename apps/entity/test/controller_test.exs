defmodule HELM.Entity.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Type.Controller, as: EntityTypeCtrl

  setup do
    {:ok, type: HRand.random_numeric_string(), id: HRand.random_numeric_string()}
  end

  test "create/1", data do
    {:ok, enty_type} = EntityTypeCtrl.create(data.type)
    assert {:ok, _} = EntityCtrl.create(enty_type.entity_type, data.id)
  end

  describe "find/1" do
    test "success", data do
      {:ok, enty_type} = EntityTypeCtrl.create(data.type)
      {:ok, enty} = EntityCtrl.create(enty_type.entity_type, data.id)
      assert {:ok, enty} = EntityCtrl.find(enty.entity_id)
    end
    
    test "failure", data do
      assert {:error, :notfound} = EntityCtrl.find("")
    end
  end

  describe "delete/1" do
    test "success", data do
      {:ok, enty_type} = EntityTypeCtrl.create(data.type)
      {:ok, enty} = EntityCtrl.create(enty_type.entity_type, data.id)
      assert {:ok, _} = EntityCtrl.delete(enty.entity_id)
    end

    test "failure", data do
      {:ok, enty_type} = EntityTypeCtrl.create(data.type)
      {:ok, enty} = EntityCtrl.create(enty_type.entity_type, data.id)
      {:ok, _} = EntityCtrl.delete(enty.entity_id)
      assert {:error, :notfound} = EntityCtrl.delete(enty.entity_id)
    end
  end
end
