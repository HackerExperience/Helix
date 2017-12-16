defmodule Helix.Server.Websocket.Channel.Server.Topics.MotherboardTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup

  @internet_id NetworkHelper.internet_id()

  describe "motherboard.update" do
    test "updates the components" do
      {socket, %{gateway: server, gateway_entity: entity}} =
        ChannelSetup.join_server(own_server: true)

      # Let's modify the server mobo to support multiple NICs
      ServerHelper.update_server_mobo(server, :mobo_999)

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {hdd, _} = ComponentSetup.component(type: :hdd)
      {nic1, _} = ComponentSetup.component(type: :nic)
      {nic2, _} = ComponentSetup.component(type: :nic)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, hdd)
      EntityAction.link_component(entity, nic1)
      EntityAction.link_component(entity, nic2)

      # We'll assign two NCs to this mobo, one public (required) and another
      # custom network
      {network, _} = NetworkSetup.network()

      # Create a new NC
      {:ok, nc_internet} =
        NetworkAction.Connection.create(@internet_id, Random.ipv4(), entity)

      {:ok, nc_custom} =
        NetworkAction.Connection.create(network, Random.ipv4(), entity)

      params =
        %{
          "motherboard_id" => to_string(server.motherboard_id),
          "slots" => %{
            "cpu_1" => to_string(cpu.component_id),
            "ram_1" => to_string(ram.component_id),
            "hdd_1" => to_string(hdd.component_id),
            "nic_1" => to_string(nic1.component_id),
            "nic_2" => to_string(nic2.component_id)
          },
          "network_connections" => %{
            to_string(nic1.component_id) => %{
              "ip" => nc_internet.ip,
              "network_id" => to_string(nc_internet.network_id)
            },
            to_string(nic2.component_id) => %{
              "ip" => nc_custom.ip,
              "network_id" => to_string(nc_custom.network_id)
            }
          }
        }

      # Request the update
      ref = push socket, "motherboard.update", params

      # It worked!
      assert_reply ref, :ok, response, timeout(:slow)

      # Empty response. It's async!
      assert Enum.empty?(response.data)

      # Client received the MotherboardUpdatedEvent
      wait_events [:motherboard_updated]

      # But the underlying server components were modified!!!
      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      # See? Components are the ones we've just created
      assert motherboard.slots.cpu_1 == cpu
      assert motherboard.slots.ram_1 == ram
      assert motherboard.slots.hdd_1 == hdd
      assert motherboard.slots.nic_1 == nic1

      # nic2 is also identical, but the component `custom` changed to point to
      # the underlying network_id. Hence, we'll ignore it for this assertion
      assert_map motherboard.slots.nic_2, nic2, skip: :custom

      # And the NetworkConnection must have also changed (nic1)
      mobo_nc1 = NetworkQuery.Connection.fetch_by_nic(nic1.component_id)

      assert mobo_nc1.network_id == nc_internet.network_id
      assert mobo_nc1.ip == nc_internet.ip

      assert motherboard.slots.nic_1.custom.network_id == nc_internet.network_id

      # NC for nic2 was updated too
      mobo_nc2 = NetworkQuery.Connection.fetch_by_nic(nic2.component_id)

      assert mobo_nc2.network_id == nc_custom.network_id
      assert mobo_nc2.ip == nc_custom.ip

      assert motherboard.slots.nic_2.custom.network_id == nc_custom.network_id
    end

    test "detaches the mobo (and unlinks the underlying components)" do
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)

      # Get current NC (used for later verification)
      %{ip: ip, network_id: network_id} = ServerHelper.get_nip(server)
      cur_nc = NetworkQuery.Connection.fetch(network_id, ip)

      # It is attached to a NIC
      nic_id = cur_nc.nic_id
      assert nic_id

      params = %{"cmd" => "detach"}

      ref = push socket, "motherboard.update", params

      # It worked!
      assert_reply ref, :ok, response, timeout(:slow)

      # Empty response. It's async!
      assert Enum.empty?(response.data)

      # Client received the MotherboardUpdatedEvent
      wait_events [:motherboard_updated]

      new_server = ServerQuery.fetch(server.server_id)

      # Motherboard is gone!
      refute new_server.motherboard_id

      # And so are all the components linked to it
      refute MotherboardQuery.fetch(server.motherboard_id)
    end
  end
end
