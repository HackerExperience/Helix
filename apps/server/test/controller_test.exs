defmodule HELM.Server.ControllerTest do
  use ExUnit.Case

  alias HELF.Broker
  alias HELM.Server.Type.Controller, as: ServerTypeCtrl
  alias HELM.Server.Controller, as: ServerCtrl
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Server.Controller, as: EntityServerCtrl

  def random_num do
    :rand.uniform(134217727)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end

  describe "HELM.Server.Type.Controller" do
    test "create/1 success" do
      assert {:ok, _} = ServerTypeCtrl.create(random_str)
    end

    test "find/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      assert {:ok, serv_type} = ServerTypeCtrl.find(serv_type.server_type)
    end

    test "all/1 success" do
      assert is_list(ServerTypeCtrl.all())
    end

    test "delete/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      assert {:ok, _} = ServerTypeCtrl.delete(serv_type.server_type)
    end
  end

  describe "HELM.Server.Controller" do
    test "create/2 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      assert {:ok, _} = ServerCtrl.create("08007277222", serv_type.server_type)
    end

    test "find/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      {:ok, serv} = ServerCtrl.create("08007277222", serv_type.server_type)
      assert {:ok, serv} = ServerCtrl.find(serv.server_id)
    end

    test "delete/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      {:ok, serv} = ServerCtrl.create("08007277222", serv_type.server_type)
      assert {:ok, _} = ServerCtrl.delete(serv.server_id)
    end

    test "attach/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      {:ok, serv} = ServerCtrl.create("08007277222", serv_type.server_type)
      {:ok, mobo_id} = Broker.call("hardware:motherboard:create", [])
      assert {:ok, _} = ServerCtrl.attach(serv.server_id, mobo_id)
    end

    test "detach/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      {:ok, serv} = ServerCtrl.create("08007277222", serv_type.server_type)
      {:ok, mobo_id} = Broker.call("hardware:motherboard:create", [])
      {:ok, _} = ServerCtrl.attach(serv.server_id, mobo_id)
      assert {:ok, _} = ServerCtrl.detach(serv.server_id)
    end
  end

  describe "HELM.Entity.Server.Controller" do
    test "create/2 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      {:ok, serv} = ServerCtrl.create("08007277222", serv_type.server_type)
      {:ok, enty} = EntityCtrl.create(%{account_id: random_str})
      assert {:ok, _} = EntityServerCtrl.create(serv.server_id, enty.entity_id)
    end

    test "find/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      {:ok, serv} = ServerCtrl.create("08007277222", serv_type.server_type)
      {:ok, enty} = EntityCtrl.create(%{account_id: random_str})
      {:ok, ent_serv} = EntityServerCtrl.create(serv.server_id, enty.entity_id)
      assert {:ok, ent_serv} = EntityServerCtrl.find(serv.server_id)
    end

    test "delete/1 success" do
      {:ok, serv_type} = ServerTypeCtrl.create(random_str)
      {:ok, serv} = ServerCtrl.create("08007277222", serv_type.server_type)
      {:ok, enty} = EntityCtrl.create(%{account_id: random_str})
      {:ok, ent_serv} = EntityServerCtrl.create(serv.server_id, enty.entity_id)
      assert {:ok, _} = EntityServerCtrl.delete(serv.server_id)
    end
  end
end
