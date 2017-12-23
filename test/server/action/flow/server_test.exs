defmodule Helix.Server.Action.Flow.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  @relay nil

  describe "setup/3" do
    test "creates desktop server from initial hardware/setup" do
      {entity, _} = EntitySetup.entity()

      # Setup the initial components & motherboard
      assert {:ok, _, mobo} = MotherboardFlow.initial_hardware(entity, @relay)

      # Setup the actual server
      assert {:ok, server} = ServerFlow.setup(:desktop, entity, mobo, @relay)

      assert server.motherboard_id == mobo.component_id
    end
  end

  describe "update_mobo/5" do
    test "motherboard is updated (same one)" do
      {server, %{entity: entity}} = ServerSetup.server()

      # Fetch current motherboard data
      mobo = ComponentQuery.fetch(server.motherboard_id)
      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      # Get current motherboard components
      [cpu] = MotherboardQuery.get_cpus(motherboard)
      [ram] = MotherboardQuery.get_rams(motherboard)
      [hdd] = MotherboardQuery.get_hdds(motherboard)
      [nic] = MotherboardQuery.get_nics(motherboard)

      # Get current NetworkConnection assigned to `old_nic`
      nc = NetworkQuery.Connection.fetch_by_nic(nic)

      # Specify the mobo components (desired state)
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

      assert {:ok, new_server, new_motherboard} =
        ServerFlow.update_mobo(
          server, motherboard, mobo_data, entity_ncs, @relay
        )

      # This is funny (and perhaps I'm tired). We've just updated the mobo with
      # the exact same components and NC as before. So, it must be identical to
      # the original values
      assert new_server == server
      assert new_motherboard == motherboard
    end
  end
end
