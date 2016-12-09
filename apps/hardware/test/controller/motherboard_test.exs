defmodule HELM.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobos

  test "create/1" do
    assert {:ok, _} = CtrlMobos.create()
  end

  describe "find/1" do
    test "fetches the model by it's id" do
      {:ok, mobo} = CtrlMobos.create()
      assert {:ok, ^mobo} = CtrlMobos.find(mobo.motherboard_id)
    end

    test "returns error when motherboard doesn't exists" do
      assert {:error, :notfound} === CtrlMobos.find(HELL.TestHelper.Random.pk())
    end
  end

  test "delete is idempotent" do
    {:ok, mobo} = CtrlMobos.create()
    assert {:ok, _} = CtrlMobos.find(mobo.motherboard_id)
    assert CtrlMobos.delete(mobo.motherboard_id)
    assert CtrlMobos.delete(mobo.motherboard_id)
    assert {:error, :notfound} === CtrlMobos.find(mobo.motherboard_id)
  end
end