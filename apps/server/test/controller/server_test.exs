defmodule HELM.Server.ControllerTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Server.Repo
  alias HELM.Server.Controller.Server, as: CtrlServer
  alias HELM.Server.Model.ServerType, as: MdlServerType

  @server_type HRand.string(min: 20)

  setup_all do
    %{server_type: @server_type}
    |> MdlServerType.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    payload = %{server_type: @server_type}
    {:ok, payload: payload}
  end

  test "create/2", %{payload: payload} do
    assert {:ok, _} = CtrlServer.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, serv} = CtrlServer.create(payload)
      assert {:ok, serv} == CtrlServer.find(serv.server_id)
    end

    test "failure" do
      assert {:error, :notfound} == CtrlServer.find(IPv6.generate([]))
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    {:ok, serv} = CtrlServer.create(payload)
    assert :ok == CtrlServer.delete(serv.server_id)
    assert :ok == CtrlServer.delete(serv.server_id)
    assert {:error, :notfound} = CtrlServer.find(serv.server_id)
  end
end