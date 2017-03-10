defmodule Helix.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController

  alias Helix.Hardware.Factory

  @moduletag :integration

  describe "find" do
    test "fetching the model by it's id" do
      mobo = Factory.insert(:motherboard)
      {:ok, found} = MotherboardController.find(mobo.motherboard_id)

      assert mobo.motherboard_id === found.motherboard_id
    end

    test "returns error when motherboard doesn't exists" do
      assert {:error, :notfound} === MotherboardController.find(Random.pk())
    end
  end


  describe "delete" do
    test "is idempotent" do
      mobo = Factory.insert(:motherboard)

      assert {:ok, _} = MotherboardController.find(mobo.motherboard_id)

      MotherboardController.delete(mobo.motherboard_id)
      MotherboardController.delete(mobo.motherboard_id)

      assert {:error, :notfound} =
        MotherboardController.find(mobo.motherboard_id)
    end

    test "removes every slot" do
      mobo = Factory.insert(:motherboard)

      refute [] === MotherboardController.get_slots(mobo.motherboard_id)

      MotherboardController.delete(mobo.motherboard_id)

      assert [] === MotherboardController.get_slots(mobo.motherboard_id)
    end
  end
end
