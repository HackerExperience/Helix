defmodule HELM.Entity.ControllerTest do
  use ExUnit.Case

  alias HELF.Broker
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Server.Controller, as: EntityServerCtrl
  alias HELM.Entity.Type.Controller, as: EntityTypeCtrl

  def random_num do
    :rand.uniform(134217727)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end

  describe "HELM.Entity.Type.Controller" do
    test "create/1 success" do
      assert {:ok, _} = EntityTypeCtrl.create(random_str)
    end

    test "find/1 success" do
      {:ok, enty_type} = EntityTypeCtrl.create(random_str)
      assert {:ok, enty_type} = EntityTypeCtrl.find(enty_type.entity_type)
    end

    test "delete/1 success" do
      {:ok, enty_type} = EntityTypeCtrl.create(random_str)
      assert {:ok, _} = EntityTypeCtrl.delete(enty_type.entity_type)
    end
  end

  describe "HELM.Entity.Controller" do
    test "create/1 success" do
      {:ok, enty_type} = EntityTypeCtrl.create(random_str)
      assert {:ok, _} = EntityCtrl.create(enty_type.entity_type, random_str)
    end

    test "find/1 success" do
      {:ok, enty_type} = EntityTypeCtrl.create(random_str)
      {:ok, enty} = EntityCtrl.create(enty_type.entity_type, random_str)
      assert {:ok, enty} = EntityCtrl.find(enty.entity_id)
    end

    test "delete/1 success" do
      {:ok, enty_type} = EntityTypeCtrl.create(random_str)
      {:ok, enty} = EntityCtrl.create(enty_type.entity_type, random_str)
      assert {:ok, _} = EntityCtrl.delete(enty.entity_id)
    end
  end
end
