defmodule Helix.Network.Event.TunnelTest do

  use Helix.Test.IntegrationCase

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Network.Internal.Tunnel, as: TunnelInternal
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  @internet Repo.get!(Network, "::")

  describe "when connection is closed" do
    test "deletes tunnel if it is empty" do
      gateway = Server.ID.generate()
      destination = Server.ID.generate()
      bounces = []

      {:ok, tunnel} = TunnelInternal.create(
        @internet,
        gateway,
        destination,
        bounces)

      {:ok, connection, _events} = TunnelInternal.start_connection(tunnel, "ssh")

      events = TunnelInternal.close_connection(connection)

      Event.emit(events)

      # Let's give it enough time to run
      :timer.sleep(100)

      refute Repo.get(Tunnel, tunnel.tunnel_id)
    end

    test "does nothing if tunnel still has connections" do
      gateway = Server.ID.generate()
      destination = Server.ID.generate()
      bounces = []

      {:ok, tunnel} = TunnelInternal.create(
        @internet,
        gateway,
        destination,
        bounces)

      TunnelInternal.start_connection(tunnel, "ssh")
      {:ok, connection, _events} = TunnelInternal.start_connection(tunnel, "ssh")

      events = TunnelInternal.close_connection(connection)

      Event.emit(events)

      # Let's give it enough time to run
      :timer.sleep(100)

      assert Repo.get(Tunnel, tunnel.tunnel_id)
    end
  end
end
