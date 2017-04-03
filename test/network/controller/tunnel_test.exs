defmodule Helix.Network.Controller.TunnelTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Network.Controller.Tunnel, as: Controller
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  @moduletag :integration

  @internet Repo.get!(Network, "::")

  describe "prepare/4" do
    test "creates a tunnel if none exists" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      {:ok, tunnel} = Controller.prepare(@internet, gateway, destination, bounces)

      assert %Tunnel{} = tunnel
      assert Repo.get_by(Tunnel, gateway_id: gateway)
    end

    test "returns a tunnel if one already exists" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      {:ok, tunnel0} = Controller.prepare(@internet, gateway, destination, bounces)
      {:ok, tunnel1} = Controller.prepare(@internet, gateway, destination, bounces)

      assert tunnel0.tunnel_id == tunnel1.tunnel_id
    end
  end

  describe "connected?/3" do
    test "returns false if there is no tunnel open linking two nodes" do
      refute Controller.connected?(Random.pk(), Random.pk())
    end

    test "returns true if there is any tunnel open linking two nodes" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      Controller.prepare(@internet, gateway, destination, bounces)

      assert Controller.connected?(gateway, destination)
    end

    @tag :pending
    test "can be filtered by network" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []
      network = :todo

      Controller.prepare(network, gateway, destination, bounces)

      refute Controller.connected?(gateway, destination, @internet)
      assert Controller.connected?(gateway, destination, network)
    end
  end

  describe "connections_through_node/1" do
    test "returns all connections that pass through node" do
      server = Random.pk()

      {:ok, tunnel1} = Controller.prepare(
        @internet,
        server,
        Random.pk(),
        [])

      Controller.start_connection(tunnel1, "ssh")

      {:ok, tunnel2} = Controller.prepare(
        @internet,
        Random.pk(),
        server,
        [])

      Controller.start_connection(tunnel2, "ssh")
      Controller.start_connection(tunnel2, "ssh")

      {:ok, tunnel3} = Controller.prepare(
        @internet,
        Random.pk(),
        Random.pk(),
        [Random.pk(), server, Random.pk(), Random.pk()])

      Controller.start_connection(tunnel3, "ssh")
      Controller.start_connection(tunnel3, "ssh")
      Controller.start_connection(tunnel3, "ssh")

      connections = Controller.connections_through_node(server)

      assert 6 == Enum.count(connections)
    end
  end

  describe "start_connection/2" do
    test "starts a new connection every call" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      {:ok, tunnel} = Controller.prepare(@internet, gateway, destination, bounces)

      {:ok, connection1} = Controller.start_connection(tunnel, "ssh")
      {:ok, connection2} = Controller.start_connection(tunnel, "ssh")

      connections = Controller.get_connections(tunnel)

      refute connection1 == connection2
      assert %Connection{} = connection1
      assert %Connection{} = connection2
      assert 2 == Enum.count(connections)
    end
  end

  describe "close_connection/2" do
    test "deletes the connection" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      {:ok, tunnel} = Controller.prepare(@internet, gateway, destination, bounces)

      {:ok, connection} = Controller.start_connection(tunnel, "ssh")

      Controller.close_connection(connection)

      refute Repo.get(Connection, connection.connection_id)
    end
  end
end
