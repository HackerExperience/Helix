defmodule Helix.Network.Service.Event.TunnelTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Event
  alias Helix.Network.Controller.Tunnel, as: Controller
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  @internet Repo.get!(Network, "::")

  describe "when connection is closed" do
    test "deletes tunnel if it is empty" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      {:ok, tunnel} = Controller.create(
        @internet,
        gateway,
        destination,
        bounces)

      {:ok, connection, _events} = Controller.start_connection(tunnel, "ssh")

      events = Controller.close_connection(connection)

      Event.emit(events)

      # Let's give it enough time to run
      :timer.sleep(100)

      refute Repo.get(Tunnel, tunnel.tunnel_id)
    end

    test "does nothing if tunnel still has connections" do
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      {:ok, tunnel} = Controller.create(
        @internet,
        gateway,
        destination,
        bounces)

      Controller.start_connection(tunnel, "ssh")
      {:ok, connection, _events} = Controller.start_connection(tunnel, "ssh")

      events = Controller.close_connection(connection)

      Event.emit(events)

      # Let's give it enough time to run
      :timer.sleep(100)

      assert Repo.get(Tunnel, tunnel.tunnel_id)
    end
  end
end
