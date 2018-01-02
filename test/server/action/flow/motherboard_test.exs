defmodule Helix.Server.Action.Flow.MotherboardTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  alias Helix.Test.Entity.Setup, as: EntitySetup

  @relay nil

  describe "initial_hardware/1" do
    test "setups initial hardware" do
      {entity, _} = EntitySetup.entity()

      assert {:ok, motherboard, _mobo} =
        MotherboardFlow.initial_hardware(entity, @relay)

      # Created the mobo
      assert MotherboardQuery.fetch(motherboard.motherboard_id)

      # All underlying components were created
      Enum.each(motherboard.slots, fn {_slot_id, component} ->
        assert ComponentQuery.fetch(component.component_id)
      end)

      # Get HDD for later usage
      [hdd] = MotherboardQuery.get_hdds(motherboard)

      # Components are linked to the entity
      owned_components = EntityQuery.get_components(entity)
      assert length(owned_components) == 5

      # Storage / StorageDrive were created and linked, respectively
      assert StorageQuery.fetch_by_hdd(hdd.component_id)

      # Let's confirm the total resources presented by the Mobo are correct
      res = MotherboardQuery.get_resources(motherboard)

      # `assert_between` is used because we do not want to test a hardcoded
      # factor of our initial hardware; instead we just want to make sure it's
      # within a specific range.
      # Note: DLK and ULK resources are empty, as a NC hasn't been assigned to
      # the NIC yet.
      assert_between res.cpu.clock, 64, 256
      assert_between res.hdd.iops, 500, 1500
      assert_between res.hdd.size, 512, 1024
    end
  end
end
