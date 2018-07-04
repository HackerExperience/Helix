defmodule Helix.Server.Henforcer.ComponentTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Server.Henforcer.Component, as: ComponentHenforcer
  alias Helix.Server.Query.Server, as: ServerQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Component.Helper, as: ComponentHelper
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id NetworkHelper.internet_id()

  describe "can_update_mobo?/4" do
    test "accepts when everything is OK" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      components = [
        {:cpu_1, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      # Create a new NC
      {:ok, new_nc} =
        NetworkAction.Connection.create(@internet_id, Random.ipv4(), entity)

      nc = %{nic.component_id => {new_nc.network_id, new_nc.ip}}

      assert {true, relay} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, components, nc
        )

      # Assigned the components (`Component.t`) to the corresponding slot
      Enum.each(relay.components, fn {component, slot_id} ->
        cond do
          slot_id == :cpu_1 ->
            assert component == cpu

          slot_id == :ram_1 ->
            assert component == ram

          slot_id == :nic_1 ->
            assert component == nic

          slot_id == :hdd_1 ->
            assert component == hdd
        end
      end)

      assert relay.entity == entity
      assert relay.mobo.component_id == server.motherboard_id
      assert length(relay.owned_components) >= 4

      # All network_connections passed as a param were added to this relay
      assert [mobo_nc] = relay.network_connections

      assert mobo_nc.nic_id == nic.component_id
      assert mobo_nc.network_id == new_nc.network_id
      assert mobo_nc.ip == new_nc.ip
      assert mobo_nc.network_connection == new_nc

      # And `entity_network_connections` has all NCs for that entity
      # (2 recently created + 1 from storyline server)
      assert length(relay.entity_network_connections) == 3

      assert_relay relay,
        [
          :entity,
          :mobo,
          :components,
          :owned_components,
          :network_connections,
          :entity_network_connections
        ]
    end

    test "rejects when component does not exist" do
      {server, %{entity: entity}} = ServerSetup.server()

      components = [{:cpu_1, ComponentHelper.id()}]

      assert {false, reason, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, components, %{}
        )

      assert reason == {:component, :not_found}
    end

    test "rejects when invalid component slots are used" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      # C1 has components on the wrong slots (RAM on CPU and versa-vice)
      c1 = [
        {:cpu_1, ram.component_id}, {:ram_1, cpu.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      assert {false, reason1, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, c1, %{}
        )

      assert reason1 == {:motherboard, :wrong_slot_type}

      # C2 has the components on the right slots but it uses an invalid one
      c2 = [
        {:cpu_999, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      assert {false, reason2, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, c2, %{}
        )

      assert reason2 == {:motherboard, :bad_slot}
    end

    test "rejects when components does not belong to entity" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      components = [
        {:cpu_1, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      assert {false, reason, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, components, %{}
        )

      assert reason == {:component, :not_belongs}
    end

    test "rejects when entity does not own the motherboard" do
      {_, %{entity: entity}} = ServerSetup.server()

      {bad_mobo, _} = ComponentSetup.component(type: :mobo)

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      components = [
        {:cpu_1, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      assert {false, reason, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, bad_mobo.component_id, components, %{}
        )

      assert reason == {:component, :not_belongs}
    end

    test "rejects when update does not match the initial components" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      # Missing `hdd`
      components = [
        {:cpu_1, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}
      ]

      assert {false, reason, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, components, %{}
        )

      assert reason == {:motherboard, :missing_initial_components}
    end

    test "rejects when given motherboard_id is not a motherboard (!!!)" do
      {_, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      components = [
        {:cpu_1, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      # Using CPU as my motherboard... because why not
      assert {false, reason, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, cpu.component_id, components, %{}
        )

      assert reason == {:component, :not_motherboard}
    end

    test "rejects when invalid NIP was assigned to the mobo" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      components = [
        {:cpu_1, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      # I'm assign `Random.ipv4()` as my NC... but it doesn't belong to me!
      nc = %{nic.component_id => {@internet_id, Random.ipv4()}}

      assert {false, reason, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, components, nc
        )

      assert reason == {:network_connection, :not_belongs}
    end

    test "rejects when no public NIC was assigned to the mobo" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      components = [
        {:cpu_1, cpu.component_id}, {:ram_1, ram.component_id},
        {:nic_1, nic.component_id}, {:hdd_1, hdd.component_id}
      ]

      {network, _} = NetworkSetup.network()

      # Create a new NC on a random network
      {:ok, new_nc} =
        NetworkAction.Connection.create(network, Random.ipv4(), entity)

      # Assign `new_nc` to the Mobo. Valid, but it has no public IP !!11!
      nc = %{nic.component_id => {new_nc.network_id, new_nc.ip}}

      assert {false, reason, _} =
        ComponentHenforcer.can_update_mobo?(
          entity.entity_id, server.motherboard_id, components, nc
        )

      assert reason == {:motherboard, :missing_public_nip}
    end
  end

  describe "can_detach_mobo?/2" do
    test "accepts when everything is a-ok" do
      {server, %{entity: entity}} = ServerSetup.server()

      assert {true, relay} =
        ComponentHenforcer.can_detach_mobo?(entity.entity_id, server.server_id)

      assert relay.server == server
      assert relay.entity == entity
      assert relay.mobo.component_id == server.motherboard_id
      assert relay.motherboard.motherboard_id == server.motherboard_id

      assert_relay relay,
        [:server, :entity, :mobo, :motherboard, :owned_components]
    end

    test "rejects when server has no mobo" do
      {server, %{entity: entity}} = ServerSetup.server()

      # Remove mobo
      ServerHelper.update_server_mobo(server, nil)

      # Look mah, no mobo!
      server = ServerQuery.fetch(server.server_id)
      refute server.motherboard_id

      assert {false, reason, _} =
        ComponentHenforcer.can_detach_mobo?(entity.entity_id, server.server_id)
      assert reason == {:motherboard, :not_attached}
    end
  end
end
