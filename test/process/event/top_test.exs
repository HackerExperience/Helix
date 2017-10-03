defmodule Helix.Process.Event.TOPTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Event.TOP, as: TOPEvent
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  test "process is killed when its connection is closed" do
    {connection, _} = NetworkSetup.fake_connection()
    {server, _} = ServerSetup.server()

    {process, _} =
      ProcessSetup.process(
        gateway_id: server.server_id,
        connection_id: connection.connection_id
      )

    event = EventSetup.connection_closed(connection)

    assert ProcessQuery.fetch(process.process_id)

    TOPEvent.connection_closed(event)

    # Give enough time for all the asynchronous stuff to happen
    :timer.sleep(50)

    refute ProcessQuery.fetch(process.process_id)
  end
end
