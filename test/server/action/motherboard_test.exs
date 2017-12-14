defmodule Helix.Server.Action.Motherboardtest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup

  describe "update/5" do
    test "updates the mobo components" do
      {server, %{entity: entity}} = ServerSetup.server()

      # Upgrade the test motherboard to one that supports multiple slots
      ServerHelper.update_server_mobo(server, :mobo_999)

      # Create `new_cpu`, `new_ram` and `new_nic`. `new_cpu` will replace the
      # server's current CPU, while `new_ram` will be added alongside the
      # current one. Same applies to `new_nic`, which will be added to
      {new_cpu, _} = ComponentSetup.component(type: :cpu)
      {new_ram, _} = ComponentSetup.component(type: :ram)
      {new_nic, _} = ComponentSetup.component(type: :nic)

      # Also create a new NetworkConnection that will replace the current one
      {new_nc, _} =
        NetworkSetup.Connection.connection(entity_id: entity.entity_id)

      # Fetch current motherboard data
      mobo = ComponentQuery.fetch(server.motherboard_id)
      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      # Get current motherboard components
      [_old_cpu] = MotherboardQuery.get_cpus(motherboard)
      [old_ram] = MotherboardQuery.get_rams(motherboard)
      [old_hdd] = MotherboardQuery.get_hdds(motherboard)
      [old_nic] = MotherboardQuery.get_nics(motherboard)

      # Get current NetworkConnection assigned to `old_nic`
      _old_nc = NetworkQuery.Connection.fetch_by_nic(old_nic)

      # Specify the mobo components (desired state)
      new_components = [
        {new_cpu, :cpu_1},
        {old_ram, :ram_1},
        {new_ram, :ram_2},
        {old_hdd, :hdd_1},
        {old_nic, :nic_1},
        {new_nic, :nic_2},
      ]

      # Notice that we are setting the `new_nc` to `old_nic`, and we did not
      # pass any information about `new_nic`. Therefore, `new_nic` will have no
      # NetworkConnection assigned to it, and `old_nc` will be replaced.
      new_network_connections =
        %{
          nic_id: old_nic.component_id,
          network_id: new_nc.network_id,
          ip: new_nc.ip,
          network_connection: new_nc
        }

      mobo_data =
        %{
          mobo: mobo,
          components: new_components,
          network_connections: [new_network_connections]
        }

      entity_ncs = NetworkQuery.Connection.get_by_entity(entity.entity_id)

      # Update
      assert {:ok, new_motherboard, _events} =
        MotherboardAction.update(motherboard, mobo_data, entity_ncs)

      assert [cpu] = MotherboardQuery.get_cpus(new_motherboard)
      assert [ram1, ram2] = MotherboardQuery.get_rams(new_motherboard)
      assert [hdd] = MotherboardQuery.get_hdds(new_motherboard)
      assert [nic1, nic2] = MotherboardQuery.get_nics(new_motherboard)

      # The CPU got replaced
      assert cpu.component_id == new_cpu.component_id

      # A new RAM component was linked to the mobo
      assert ram1.component_id == old_ram.component_id
      assert ram2.component_id == new_ram.component_id

      # Same goes for NIC
      assert nic1.component_id == old_nic.component_id
      assert nic2.component_id == new_nic.component_id

      # But HDD is still the same old love
      assert hdd.component_id == old_hdd.component_id

      # OK, if we reached here then the Mobo got updated just fine. Now let's
      # see if the NetworkConnections were updated too

      # The new NetworkConnection (`new_nc`) was assigned to `old_nic`
      current_nc = NetworkQuery.Connection.fetch_by_nic(old_nic)

      assert current_nc.ip == new_nc.ip
      assert current_nc.network_id == new_nc.network_id
      assert current_nc.nic_id == old_nic.component_id

      # New nic has no NetworkConnection assigned to it
      refute NetworkQuery.Connection.fetch_by_nic(new_nic)
    end

    test "updates the mobo (on a server that had no mobo)" do
      {server, %{entity: entity}} = ServerSetup.server()

      # Note: we are "cheating" - we are directly setting the server mobo to nil
      # This will work for this test, but won't invalidate cache, or the current
      # mobo NC, for instance.
      ServerHelper.update_server_mobo(server, nil)

      # Server has no mobo
      server = ServerQuery.fetch(server.server_id)
      refute server.motherboard_id

      # Generate brand new components
      {mobo, _} = ComponentSetup.component(type: :mobo)
      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      # Generate NetworkConnection
      {nc, _} =
        NetworkSetup.Connection.connection(entity_id: entity.entity_id)

      # Declare mobo data
      new_components = [
        {cpu, :cpu_1},
        {ram, :ram_1},
        {hdd, :hdd_1},
        {nic, :nic_1},
      ]

      new_network_connections =
        %{
          nic_id: nic.component_id,
          network_id: nc.network_id,
          ip: nc.ip,
          network_connection: nc
        }

      mobo_data =
        %{
          mobo: mobo,
          components: new_components,
          network_connections: [new_network_connections]
        }

      entity_ncs = NetworkQuery.Connection.get_by_entity(entity.entity_id)

      # Update
      assert {:ok, new_motherboard, _events} =
        MotherboardAction.update(nil, mobo_data, entity_ncs)

      assert new_motherboard.motherboard_id == mobo.component_id

      # `new_components` were linked to the mobo
      assert new_motherboard.slots.cpu_1 == cpu
      assert new_motherboard.slots.ram_1 == ram
      assert new_motherboard.slots.hdd_1 == hdd
      assert new_motherboard.slots.nic_1 == nic

      # `nc` was assigned to `nic`
      current_nc = NetworkQuery.Connection.fetch_by_nic(nic)

      assert current_nc.ip == nc.ip
      assert current_nc.network_id == nc.network_id
      assert current_nc.nic_id == nic.component_id
    end

    test "updates the mobo (on a server that had a different mobo)" do
      {server, %{entity: entity}} = ServerSetup.server()

      # Create the new mobo that we'll replace
      {new_mobo, _} = ComponentSetup.component(type: :mobo)

      # Fetch current motherboard data
      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      # Get current motherboard components
      [old_cpu] = MotherboardQuery.get_cpus(motherboard)
      [old_ram] = MotherboardQuery.get_rams(motherboard)
      [old_hdd] = MotherboardQuery.get_hdds(motherboard)
      [old_nic] = MotherboardQuery.get_nics(motherboard)

      # Get current NetworkConnection assigned to `old_nic`
      nc = NetworkQuery.Connection.fetch_by_nic(old_nic)

      # We'll add to the new mobo the previous mobo's components
      new_components = [
        {old_cpu, :cpu_1},
        {old_ram, :ram_1},
        {old_hdd, :hdd_1},
        {old_nic, :nic_1}
      ]

      # We are setting to the old nic (on a new mobo) the old NC
      new_network_connections =
        %{
          nic_id: old_nic.component_id,
          network_id: nc.network_id,
          ip: nc.ip,
          network_connection: nc
        }

      mobo_data =
        %{
          mobo: new_mobo,
          components: new_components,
          network_connections: [new_network_connections]
        }

      entity_ncs = NetworkQuery.Connection.get_by_entity(entity.entity_id)

      # Update
      assert {:ok, new_motherboard, _events} =
        MotherboardAction.update(motherboard, mobo_data, entity_ncs)

      # The motherboard was changed to `new_mobo`
      assert new_motherboard.motherboard_id == new_mobo.component_id

      # But it has the same slots (components) as the previous one
      assert new_motherboard.slots == motherboard.slots

      # And it has the same NC as before (on the same NIC)
      current_nc = NetworkQuery.Connection.fetch_by_nic(old_nic)
      assert current_nc == nc
    end
  end
end
