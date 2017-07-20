defmodule Helix.Network.Internal.TunnelTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Network.Internal.Tunnel, as: TunnelInternal
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  alias Helix.Network.Factory

  @internet Repo.get!(Network, "::")

  describe "connected?/3" do
    test "returns false if there is no tunnel open linking two nodes" do
      refute TunnelInternal.connected?(Random.pk(), Random.pk())
    end

    test "returns true if there is any tunnel open linking two nodes" do
      tunnel = Factory.insert(:tunnel, network: @internet)
      gateway = tunnel.gateway_id
      destination = tunnel.destination_id

      assert TunnelInternal.connected?(gateway, destination)
    end

    @tag :pending
    test "can be filtered by network" do
      tunnel = Factory.insert(:tunnel, network: :todo)
      network = tunnel.network
      gateway = tunnel.gateway_id
      destination = tunnel.destination_id

      refute TunnelInternal.connected?(gateway, destination, @internet)
      assert TunnelInternal.connected?(gateway, destination, network)
    end
  end

  describe "connections_through_node/1" do
    test "returns all connections that pass through node" do
      server = Random.pk()

      tunnel1 = Factory.insert(:tunnel,
        network: @internet,
        gateway_id: server)

      TunnelInternal.start_connection(tunnel1, "ssh")

      tunnel2 = Factory.insert(:tunnel,
        network: @internet,
        destination_id: server)

      TunnelInternal.start_connection(tunnel2, "ssh")
      TunnelInternal.start_connection(tunnel2, "ssh")

      tunnel3 = Factory.insert(:tunnel,
        network: @internet,
        bounces: [Random.pk(), server, Random.pk(), Random.pk()])

      TunnelInternal.start_connection(tunnel3, "ssh")
      TunnelInternal.start_connection(tunnel3, "ssh")
      TunnelInternal.start_connection(tunnel3, "ssh")

      connections = TunnelInternal.connections_through_node(server)

      assert 6 == Enum.count(connections)
    end
  end

  describe "inbound_connections/1" do
    test "list the conections that are incident on node" do
      server = Random.pk()

      tunnel1 = Factory.insert(:tunnel,
        network: @internet,
        gateway_id: server,
        bounces: [Random.pk(), Random.pk()])

      # This is not incident since the connection emanates from the server
      TunnelInternal.start_connection(tunnel1, "ssh")

      tunnel2 = Factory.insert(:tunnel,
        network: @internet,
        destination_id: server,
        bounces: [Random.pk(), Random.pk()])
      # Those are incident because they emanate from a gateway node onto the
      # bounce nodes and finally on the server
      TunnelInternal.start_connection(tunnel2, "ssh")
      TunnelInternal.start_connection(tunnel2, "ssh")

      tunnel3 = Factory.insert(:tunnel,
        network: @internet,
        bounces: [Random.pk(), server, Random.pk()])

      # Those are also incident as they emanate from the gateway, onto the
      # bounces, onto the specified target and onto the destination
      TunnelInternal.start_connection(tunnel3, "ssh")
      TunnelInternal.start_connection(tunnel3, "ssh")
      TunnelInternal.start_connection(tunnel3, "ssh")

      connections = TunnelInternal.inbound_connections(server)

      assert 5 == Enum.count(connections)
    end
  end

  describe "outbound_connections/1" do
    test "list the conections that emanate from node" do
      server = Random.pk()

      tunnel1 = Factory.insert(:tunnel,
        network: @internet,
        gateway_id: server,
        bounces: [Random.pk(), Random.pk()])

      # This emanates from the server since it goes from the server to the
      # bounces and finally to the destination
      TunnelInternal.start_connection(tunnel1, "ssh")

      tunnel2 = Factory.insert(:tunnel,
        network: @internet,
        destination_id: server,
        bounces: [Random.pk(), Random.pk()])

      # Those don't emanate from the server as the connection is incident on it
      TunnelInternal.start_connection(tunnel2, "ssh")
      TunnelInternal.start_connection(tunnel2, "ssh")

      tunnel3 = Factory.insert(:tunnel,
        network: @internet,
        bounces: [Random.pk(), server, Random.pk()])

      # Those do emanate from server onto another bounce and finally on the
      # destination
      TunnelInternal.start_connection(tunnel3, "ssh")
      TunnelInternal.start_connection(tunnel3, "ssh")
      TunnelInternal.start_connection(tunnel3, "ssh")

      connections = TunnelInternal.outbound_connections(server)

      assert 4 == Enum.count(connections)
    end
  end

  describe "start_connection/2" do
    test "starts a new connection every call" do
      tunnel = Factory.insert(:tunnel, network: @internet)

      {:ok, connection1, _events} = TunnelInternal.start_connection(tunnel, "ssh")
      {:ok, connection2, _events} = TunnelInternal.start_connection(tunnel, "ssh")

      connections = TunnelInternal.get_connections(tunnel)

      refute connection1 == connection2
      assert %Connection{} = connection1
      assert %Connection{} = connection2
      assert 2 == Enum.count(connections)
    end
  end

  describe "close_connection/2" do
    test "deletes the connection" do
      tunnel = Factory.insert(:tunnel, network: @internet)

      {:ok, connection, _events} = TunnelInternal.start_connection(tunnel, "ssh")

      TunnelInternal.close_connection(connection)

      refute Repo.get(Connection, connection.connection_id)
    end
  end
end
