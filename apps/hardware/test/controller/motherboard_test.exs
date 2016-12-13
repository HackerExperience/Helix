defmodule HELM.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentType
  alias HELM.Hardware.Model.Motherboard
  alias HELM.Hardware.Controller.Component, as: ComponentController
  alias HELM.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias HELM.Hardware.Controller.Motherboard, as: MotherboardController
  alias HELM.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController

  setup_all do
    slot_type = "MotherboardSlot Type"
    mobo_type = "Motherboard Type"

    component_type(slot_type)
    component_type(mobo_type)

    slot_a = Burette.Number.digits(4)
    slot_b = Burette.Number.digits(4)

    spec_for_motherboard = %{
      spec_type: mobo_type,
      slots: %{
        slot_a => %{type: slot_type},
        slot_b => %{type: slot_type}
      }
    }

    spec_params = %{
      component_type: mobo_type,
      spec: spec_for_motherboard
    }

    {:ok, spec} = ComponentSpecController.create(spec_params)

    [
      mobo_type: mobo_type,
      slot_type: slot_type,
      spec_id: spec.spec_id]
  end

  setup context do
    mobo_component_params = %{
      component_type: context.mobo_type,
      spec_id: context.spec_id
    }

    {:ok, mobo_component} = ComponentController.create(mobo_component_params)

    motherboard_params = %{
      motherboard_id: mobo_component.component_id
    }

    {:ok, motherboard} = MotherboardController.create(motherboard_params)

    {:ok, mobo: motherboard}
  end

  # FIXME
  defp component_type(name) do
    case Repo.get_by(ComponentType, component_type: name) do
      nil ->
        %{component_type: name}
        |> ComponentType.create_changeset()
        |> Repo.insert!()
      component_type ->
        component_type
    end
  end

  describe "find" do
    test "fetching the model by it's id", %{mobo: mobo} do
      {:ok, found} = MotherboardController.find(mobo.motherboard_id)
      assert mobo.motherboard_id === found.motherboard_id
    end

    test "returns error when motherboard doesn't exists" do
      assert {:error, :notfound} === MotherboardController.find(HELL.TestHelper.Random.pk())
    end
  end

  test "delete is idempotent and removes every slot", %{mobo: mobo} do
    assert Repo.get_by(Motherboard, motherboard_id: mobo.motherboard_id)
    refute [] === MotherboardSlotController.find_by(motherboard_id: mobo.motherboard_id)

    MotherboardController.delete(mobo.motherboard_id)
    MotherboardController.delete(mobo.motherboard_id)

    refute Repo.get_by(Motherboard, motherboard_id: mobo.motherboard_id)
    assert [] === MotherboardSlotController.find_by(motherboard_id: mobo.motherboard_id)
  end
end