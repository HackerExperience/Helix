defmodule Helix.Process.Event.Handler.TOPTest do

  use Helix.Test.Case.Integration

  alias Helix.Event
  alias Helix.Process.Internal.Process, as: ProcessInternal
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.FakeDefaultProcess
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  test "process is killed when its originating connection is closed" do
    {connection, _} = NetworkSetup.fake_connection()
    {server, _} = ServerSetup.server()

    # Create a FakeDefaultProcess, a process that we know will always use the
    # default callbacks defined by Processable
    {_, %{params: params}} =
      ProcessSetup.fake_process(
        gateway_id: server.server_id,
        connection_id: connection.connection_id,
      )

    params =
      params
      |> Map.replace(:data, FakeDefaultProcess.new())
      |> Map.replace(:type, :fake_default_process)

    {:ok, process} = ProcessInternal.create(params)

    # Fake ConnectionClosedEvent
    event = EventSetup.Network.connection_closed(connection)

    # Process exists
    assert ProcessQuery.fetch(process.process_id)

    # Simulate emission of ConnectionClosedEvent
    Event.emit(event)

    # Process no longer exists
    refute ProcessQuery.fetch(process.process_id)

    TOPHelper.top_stop()
  end

  test "process is killed when its targeting connection is closed" do
    {connection, _} = NetworkSetup.fake_connection()
    {server, _} = ServerSetup.server()

    {_, %{params: params}} =
      ProcessSetup.fake_process(
        gateway_id: server.server_id,
        target_connection_id: connection.connection_id,
      )

    params =
      params
      |> Map.replace(:data, FakeDefaultProcess.new())
      |> Map.replace(:type, :fake_default_process)

    {:ok, process} = ProcessInternal.create(params)

    # Fake ConnectionClosedEvent
    event = EventSetup.Network.connection_closed(connection)

    # Process exists
    assert ProcessQuery.fetch(process.process_id)

    # Simulate emission of ConnectionClosedEvent
    Event.emit(event)

    # Process no longer exists
    refute ProcessQuery.fetch(process.process_id)

    TOPHelper.top_stop()
  end
end
