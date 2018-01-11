defmodule Helix.Server.Websocket.Requests.MotherboardUpdateTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros

  alias Helix.Websocket.Requestable
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Component
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Server.Websocket.Requests.MotherboardUpdate,
    as: MotherboardUpdateRequest

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id NetworkHelper.internet_id()

  @mock_socket ChannelSetup.mock_server_socket(access: :local)

  describe "MotherboardUpdateRequest.check_params" do
    test "casts the params to internal Helix format" do
      params =
        %{
          "motherboard_id" => "::1",
          "slots" => %{
            "cpu_1" => "::f",
            "ram_1" => nil,
          },
          "network_connections" => %{
            "::5" => %{
              "network_id" => "::",
              "ip" => "1.2.3.4"
            }
          }
        }

      req = MotherboardUpdateRequest.new(params)
      assert {:ok, req} = Requestable.check_params(req, @mock_socket)

      assert req.params.cmd == :update
      assert req.params.mobo_id == Component.ID.cast!(params["motherboard_id"])
      assert req.params.slots.cpu_1 == Component.ID.cast!("::f")
      refute req.params.slots.ram_1

      [{nic_id, nip}] = req.params.network_connections

      assert nic_id == Component.ID.cast!("::5")
      assert nip == {Network.ID.cast!("::"), "1.2.3.4"}
    end

    test "infers players want to detach mobo when params are empty" do
      params = %{"cmd" => "detach"}

      req = MotherboardUpdateRequest.new(params)
      assert {:ok, req} = Requestable.check_params(req, @mock_socket)

      assert req.params.cmd == :detach
    end

    test "handles invalid slot data" do
      base_params = %{"motherboard_id" => "::"}

      # Invalid component type `notexists`
      p1 =
        %{
          "slots" => %{"notexists_50" => "::"}
        } |> Map.merge(base_params)

      # Invalid slot `abc`
      p2 =
        %{
          "slots" => %{"cpu_abc" => nil}
        } |> Map.merge(base_params)

      # Invalid component ID `wtf`
      p3 =
        %{
          "slots" => %{"cpu_1" => "wtf"}
        } |> Map.merge(base_params)

      # Empty slots
      p4 = base_params

      req1 = MotherboardUpdateRequest.new(p1)
      req2 = MotherboardUpdateRequest.new(p2)
      req3 = MotherboardUpdateRequest.new(p3)
      req4 = MotherboardUpdateRequest.new(p4)

      assert {:error, %{message: reason1}, _} =
        Requestable.check_params(req1, @mock_socket)
      assert {:error, %{message: reason2}, _} =
        Requestable.check_params(req2, @mock_socket)
      assert {:error, %{message: reason3}, _} =
        Requestable.check_params(req3, @mock_socket)
      assert {:error, %{message: reason4}, _} =
        Requestable.check_params(req4, @mock_socket)

      assert reason1 == "bad_slot_data"
      assert reason2 == reason1
      assert reason3 == reason2
      assert reason4 == reason3
    end

    test "handles invalid network connections" do
      base_params =
        %{
          "motherboard_id" => "::f",
          "slots" => %{"cpu_1" => "::1"},
        }

      # Empty NCs
      p1 = base_params

      # Invalid NIC ID
      p2 =
        %{
          "network_connections" => %{
            "invalid_component" => %{
              "ip" => "1.2.3.4",
              "network_id" => "::"
            }
          }
        } |> Map.merge(base_params)

      # Invalid IP
      p3 =
        %{
          "network_connections" => %{
            "::f" => %{
              "ip" => "abc",
              "network_id" => "::"
            }
          }
        } |> Map.merge(base_params)

      # Invalid network ID
      p4 =
        %{
          "network_connections" => %{
            "::f" => %{
              "ip" => "127.0.0.1",
              "network_id" => "invalid"
            }
          }
        } |> Map.merge(base_params)

      req1 = MotherboardUpdateRequest.new(p1)
      req2 = MotherboardUpdateRequest.new(p2)
      req3 = MotherboardUpdateRequest.new(p3)
      req4 = MotherboardUpdateRequest.new(p4)

      assert {:error, %{message: reason1}, _} =
        Requestable.check_params(req1, @mock_socket)
      assert {:error, %{message: reason2}, _} =
        Requestable.check_params(req2, @mock_socket)
      assert {:error, %{message: reason3}, _} =
        Requestable.check_params(req3, @mock_socket)
      assert {:error, %{message: reason4}, _} =
        Requestable.check_params(req4, @mock_socket)

      assert reason1 == "bad_network_connections"
      assert reason2 == reason1
      assert reason3 == reason2
      assert reason4 == reason3
    end
  end

  describe "MotherboardUpdateRequest.check_permissions" do
    test "accepts when data is valid (update)" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      # Create a new NC
      {:ok, new_nc} =
        NetworkAction.Connection.create(@internet_id, Random.ipv4(), entity)

      params =
        %{
          "motherboard_id" => to_string(server.motherboard_id),
          "slots" => %{
            "cpu_1" => to_string(cpu.component_id),
            "ram_1" => to_string(ram.component_id),
            "hdd_1" => to_string(hdd.component_id),
            "nic_1" => to_string(nic.component_id)
          },
          "network_connections" => %{
            to_string(nic.component_id) => %{
              "ip" => new_nc.ip,
              "network_id" => to_string(new_nc.network_id)
            }
          }
        }

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: server.server_id,
          gateway_entity_id: entity.entity_id,
          access: :local
        )

      request = MotherboardUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.components
      assert request.meta.owned_components
      assert request.meta.network_connections
      assert request.meta.entity_network_connections
    end

    @tag :regression
    test "rejects when it's missing the minimum components" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      # Create a new NC
      {:ok, new_nc} =
        NetworkAction.Connection.create(@internet_id, Random.ipv4(), entity)

      random_component = Enum.random(["cpu_1", "ram_1", "nic_1", "hdd_1"])

      params =
        %{
          "motherboard_id" => to_string(server.motherboard_id),
          "slots" => %{
            "cpu_1" => to_string(cpu.component_id),
            "ram_1" => to_string(ram.component_id),
            "hdd_1" => to_string(hdd.component_id),
            "nic_1" => to_string(nic.component_id)
          },
          "network_connections" => %{
            to_string(nic.component_id) => %{
              "ip" => Random.ipv4(),  # This IP does not belong to me!!11!
              "network_id" => to_string(new_nc.network_id)
            }
          }
        }
        # This will ensure one of the slots will be missing its component
        |> put_in(["slots", random_component], nil)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: server.server_id,
          gateway_entity_id: entity.entity_id,
          access: :local
        )

      request = MotherboardUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

      assert reason == "motherboard_missing_initial_components"
    end

    test "rejects when something nip is invalid" do
      {server, %{entity: entity}} = ServerSetup.server()

      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.component(type: :nic)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      EntityAction.link_component(entity, cpu)
      EntityAction.link_component(entity, ram)
      EntityAction.link_component(entity, nic)
      EntityAction.link_component(entity, hdd)

      # Create a new NC
      {:ok, new_nc} =
        NetworkAction.Connection.create(@internet_id, Random.ipv4(), entity)

      # Note: for a full test of the validation see `ComponentHenforcerTest`
      params =
        %{
          "motherboard_id" => to_string(server.motherboard_id),
          "slots" => %{
            "cpu_1" => to_string(cpu.component_id),
            "ram_1" => to_string(ram.component_id),
            "hdd_1" => to_string(hdd.component_id),
            "nic_1" => to_string(nic.component_id)
          },
          "network_connections" => %{
            to_string(nic.component_id) => %{
              "ip" => Random.ipv4(),  # This IP does not belong to me!!11!
              "network_id" => to_string(new_nc.network_id)
            }
          }
        }

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: server.server_id,
          gateway_entity_id: entity.entity_id,
          access: :local
        )

      request = MotherboardUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

      assert reason == "network_connection_not_belongs"
    end

    test "accepts when data is valid (detach)" do
      {server, %{entity: entity}} = ServerSetup.server()

      params = %{"cmd" => "detach"}

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: server.server_id,
          gateway_entity_id: entity.entity_id,
          access: :local
        )

      request = MotherboardUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.server == server
    end
  end

  describe "MotherboardUpdateRequest.handle_request" do
    test "updates the motherboard" do
      {server, %{entity: entity}} = ServerSetup.server()

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

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: server.server_id,
          gateway_entity_id: entity.entity_id,
          access: :local
        )

      request = MotherboardUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, _request} = Requestable.handle_request(request, socket)

      # Since updating the motherboard is asynchronous, we won't receive any
      # information on the `request` returned at `handle_request/2`, and as such
      # we'll proceed to render the empty request.
      # However, the server mobo must have changed:

      # The new server is identical to the previous one, since we did not change
      # the motherboard itself
      new_server = ServerQuery.fetch(server.server_id)
      assert new_server == server

      # The components linked to the mobo have changed too!
      motherboard = MotherboardQuery.fetch(new_server.motherboard_id)

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

    test "detaches the motherboard" do
      {server, %{entity: entity}} = ServerSetup.server()

      # Get current NC (used for later verification)
      %{ip: ip, network_id: network_id} = ServerHelper.get_nip(server)
      cur_nc = NetworkQuery.Connection.fetch(network_id, ip)

      # It is attached to a NIC
      nic_id = cur_nc.nic_id
      assert nic_id

      params = %{"cmd" => "detach"}

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: server.server_id,
          gateway_entity_id: entity.entity_id,
          access: :local
        )

      request = MotherboardUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, _request} = Requestable.handle_request(request, socket)

      # Detaching is asynchronous, so we don't care about the returned value of
      # `handle_request/2`. Now we must make sure that the mobo was detached.

      new_server = ServerQuery.fetch(server.server_id)

      # Motherboard is gone!
      refute new_server.motherboard_id

      # And so are all the components linked to it
      refute MotherboardQuery.fetch(server.motherboard_id)

      # Underlying components still exist (but they are not linked to any mobo)
      assert ComponentQuery.fetch(nic_id)

      # Old NIC points to no NC (i.e. no NCs are assigned to the NIC)
      refute NetworkQuery.Connection.fetch_by_nic(nic_id)

      # Old NIP still exists - but it's unused
      new_nc = NetworkQuery.Connection.fetch(network_id, ip)

      assert new_nc.network_id == network_id
      assert new_nc.ip == ip
      assert new_nc.entity_id == entity.entity_id
      refute new_nc.nic_id
    end
  end
end
