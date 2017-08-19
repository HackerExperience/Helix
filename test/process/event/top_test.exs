defmodule Helix.Process.Event.TOPTest do

  use Helix.Test.Case.Integration

  alias Helix.Hardware.Action.Motherboard, as: MotherboardAction
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo
  alias Helix.Process.Event.TOP, as: TOPEvent

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Hardware.Factory, as: HardwareFactory
  alias Helix.Test.Server.Factory, as: ServerFactory
  alias Helix.Test.Process.Factory

  # FIXME
  defp reason_we_need_integration_factories do
    server = ServerFactory.insert(:server)

    motherboard = HardwareFactory.insert(:motherboard)

    motherboard.slots
    |> Enum.group_by(&(&1.link_component_type))
    |> Enum.map(fn {_, [v| _]} -> v end)
    |> Enum.each(fn slot ->
      # FIXME: Move the "Fixture" module into the factory module
      component = Helix.Test.Hardware.Fixture.insert(slot.link_component_type)

      MotherboardAction.link(slot, component)
    end)

    {:ok, server} = ServerAction.attach(server, motherboard.motherboard_id)

    CacheHelper.sync_test()

    server
  end

  test "process is killed when its connection is closed" do
    connection_id = Connection.ID.generate()

    server = reason_we_need_integration_factories()

    process = Factory.insert(
      :process,
      connection_id: connection_id,
      gateway_id: server.server_id)

    # TODO: factories for events ?
    event = %ConnectionClosedEvent{
      connection_id: connection_id,
      network_id: Network.ID.generate(),
      tunnel_id: Tunnel.ID.generate(),
      reason: :shutdown,
      meta: nil,
      connection_type: :ssh
    }

    assert Repo.get(Process, process.process_id)

    TOPEvent.connection_closed(event)

    # Give enough time for all the asynchronous stuff to happen
    :timer.sleep(50)

    refute Repo.get(Process, process.process_id)
  end
end
