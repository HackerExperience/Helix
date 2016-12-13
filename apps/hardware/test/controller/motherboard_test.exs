defmodule HELM.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6, warn: false
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentType
  alias HELM.Hardware.Model.ComponentSpec
  alias HELM.Hardware.Model.Motherboard
  alias HELM.Hardware.Controller.Component, as: ComponentController
  alias HELM.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias HELM.Hardware.Controller.Motherboard, as: MotherboardController
  alias HELM.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController

  setup do
    mobo_type = component_type("Motherboard_" <> Burette.Number.digits(8))
    slot_type = component_type(Burette.Color.name())

    spec_for(slot_type)
    mobo_spec = spec_for(mobo_type, motherboard?: true, slot_type: slot_type)

    mobo_component_params = %{
      component_type: mobo_type.component_type,
      spec_id: mobo_spec.spec_id
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
        ComponentType.create_changeset(%{component_type: name})
        |> Repo.insert!()
      component_type ->
        component_type
    end
  end

  defp spec_for(component_type, [motherboard?: true, slot_type: slot_type]) do
    case Repo.get_by(ComponentSpec, component_type: component_type.component_type) do
      nil ->
        slot_a = Burette.Number.digits(4)
        slot_b = Burette.Number.digits(4)

        spec_for_motherboard = %{
          spec_type: component_type.component_type,
          slots: %{
            slot_a => %{type: slot_type.component_type},
            slot_b => %{type: slot_type.component_type}
          }
        }

        spec_params = %{
          component_type: component_type.component_type,
          spec: spec_for_motherboard
        }

        {:ok, spec} = ComponentSpecController.create(spec_params)
        spec
      component_spec ->
        component_spec
    end
  end

  defp spec_for(component_type) do
    case Repo.get_by(ComponentSpec, component_type: component_type.component_type) do
      nil ->
        spec_params = %{
          component_type: component_type.component_type,
          spec: %{}
        }

        {:ok, spec} = ComponentSpecController.create(spec_params)
        spec
      component_spec ->
        component_spec
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

    assert {:error, :notfound} == MotherboardController.find(mobo.motherboard_id)
    assert [] === MotherboardSlotController.find_by(motherboard_id: mobo.motherboard_id)
  end
end