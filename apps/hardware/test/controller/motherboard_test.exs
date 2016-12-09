defmodule HELM.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobos
  alias HELL.IPv6, warn: false
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Controller.Component, as: CtrlComp
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec
  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobo
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot
  import Ecto.Query, only: [where: 3]

  @motherboard_spec %{
    spec_type: "mobo",
    slots: %{
      "0" => %{
        type: "cpu"
      },
      "1" => %{
        type: "hdd",
        limit: 2000
      },
      "2" => %{
        type: "hdd",
        limit: 2000
      },
      "3" => %{
        type: "ram",
        limit: 4096
      },
      "4" => %{
        type: "ram",
        limit: 4096
      },
      "5" => %{
        type: "nic",
        limit: 1000
      },
      "6" => %{
        type: "nic",
        limit: 1000
      }
    }
  }

  setup_all do
    :ok
  end

  setup do
    payload = %{
      component_type: @motherboard_spec.spec_type,
      spec: @motherboard_spec
    }

    {:ok, spec} = CtrlCompSpec.create(payload)

    payload = %{
      component_type: @motherboard_spec.spec_type,
      spec_id: spec.spec_id
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