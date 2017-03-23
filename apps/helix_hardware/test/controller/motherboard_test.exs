defmodule Helix.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Repo

  @moduletag :integration

  setup_all do
    {:ok, spec} = ComponentSpecController.create(motherboard_spec())

    {:ok, component_spec: spec}
  end

  setup context do
    {:ok, component} = ComponentController.create_from_spec(context.component_spec)

    mobo = Repo.get_by(Motherboard, motherboard_id: component.component_id)

    {:ok, mobo: mobo}
  end

  describe "find" do
    test "fetching the model by it's id", %{mobo: mobo} do
      {:ok, found} = MotherboardController.find(mobo.motherboard_id)
      assert mobo.motherboard_id === found.motherboard_id
    end

    test "returns error when motherboard doesn't exists" do
      assert {:error, :notfound} === MotherboardController.find(Random.pk())
    end
  end

  test "delete is idempotent and removes every slot", %{mobo: mobo} do
    assert Repo.get_by(Motherboard, motherboard_id: mobo.motherboard_id)
    refute [] === MotherboardController.get_slots(mobo.motherboard_id)

    MotherboardController.delete(mobo.motherboard_id)
    MotherboardController.delete(mobo.motherboard_id)

    refute Repo.get_by(Motherboard, motherboard_id: mobo.motherboard_id)
    assert [] === MotherboardController.get_slots(mobo.motherboard_id)
  end

  defp motherboard_spec do
    total_slots = Random.number(1..20)
    slots = for x <- 0..(total_slots - 1), into: %{} do
      xs = %{"type" => Enum.random(["CPU", "HDD", "RAM", "NIC"])}
      {to_string(x), xs}
    end

    %{
      "spec_code" => String.upcase(Random.string(min: 10)),
      "spec_type" => "MOBO",
      "name" => Random.string(min: 9),
      "slots" => slots
    }
  end
end
