defmodule HELM.Server.ControllerTest do
  use ExUnit.Case

  alias HELM.Server.Type.Controller, as: ServerTypeCtrl
  alias HELM.Server.Controller, as: ServerCtrl

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
  end
end
