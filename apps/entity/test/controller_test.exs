defmodule HELM.Entity.ControllerTest do
  use ExUnit.Case

  alias HELF.Broker
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Server.Controller, as: EntityServerCtrl

  def random_num do
    :rand.uniform(134217727)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end

  describe "HELM.Entity.Controller" do
    test "create/1 account success" do
      assert {:ok, _} = EntityCtrl.create(%{account_id: random_str})
    end

    test "find/1 success" do
      {:ok, entity} = EntityCtrl.create(%{account_id: random_str})
      assert {:ok, entity} = EntityCtrl.find(entity.entity_id)
    end

    test "delete/1 success" do
      {:ok, entity} = EntityCtrl.create(%{account_id: random_str})
      assert {:ok, _} = EntityCtrl.delete(entity.entity_id)
    end
  end
end
