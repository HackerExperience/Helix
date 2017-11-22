defmodule Helix.Server.Action.Flow.MotherboardTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet_id NetworkHelper.internet_id()
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

      # Get NIC and HDD for later usage
      [nic] = MotherboardQuery.get_nics(motherboard)
      [hdd] = MotherboardQuery.get_hdds(motherboard)

      # Components are linked to the entity
      owned_components = EntityQuery.get_components(entity)
      assert length(owned_components) == 4

      # NIC has NC assigned to it
      nc = NetworkQuery.Connection.fetch_by_nic(nic)

      assert nc.network_id == @internet_id
      assert nc.ip
      assert nc.nic_id == nic.component_id

      # Storage / StorageDrive were created and linked, respectively
      assert StorageQuery.fetch_by_hdd(hdd.component_id)

      # Let's confirm the total resources presented by the Mobo are correct
      res = MotherboardQuery.get_resources(motherboard)

      # `assert_between` is used because we do not want to test a hardcoded
      # factor of our initial hardware; instead we just want to make sure it's
      # within a specific range.
      assert_between res.cpu.clock, 64, 256
      assert_between res.hdd.iops, 500, 1500
      assert_between res.hdd.size, 512, 1024
      assert_between res.net[@internet_id].dlk, 56, 128
      assert_between res.net[@internet_id].ulk, 16, 32
    end
  end
end
