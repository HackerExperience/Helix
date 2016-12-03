defmodule HELM.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobos
  alias HELL.IPv6, warn: false
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Controller.Component, as: CtrlComp
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec
  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobo
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot
  import Ecto.Query, only: [where: 3]

  @motherboard_spec %{
    spec_id: HRand.string(min: 8, max: 8),
    spec_type: "MOBO",
    name: HRand.string(min: 16, max: 20),
    slots: %{
      "0" => %{
        type: "CPU"
      },
      "1" => %{
        type: "HDD",
        limit: 2000
      },
      "2" => %{
        type: "HDD",
        limit: 2000
      },
      "3" => %{
        type: "RAM",
        limit: 4096
      },
      "4" => %{
        type: "RAM",
        limit: 4096
      },
      "5" => %{
        type: "NIC",
        limit: 1000
      },
      "6" => %{
        type: "NIC",
        limit: 1000
      }
    }
  }

  setup_all do
    payload = %{
      spec_id: @motherboard_spec.spec_id,
      component_type: @motherboard_spec.spec_type,
      spec: @motherboard_spec
    }
    {:ok, _} = CtrlCompSpec.create(payload)
    :ok
  end

  setup do
    payload = %{
      component_type: @motherboard_spec.spec_type,
      spec_id: @motherboard_spec.spec_id
    }
    {:ok, component} = CtrlComp.create(payload)
    {:ok, payload: %{motherboard_id: component.component_id}}
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