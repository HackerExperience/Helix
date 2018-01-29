defmodule Helix.Test.Event.Setup.Network do

  alias Helix.Network.Model.Connection

  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent
  alias Helix.Network.Event.Connection.Started, as: ConnectionStartedEvent

  alias Helix.Test.Network.Setup, as: NetworkSetup

  def connection_started,
    do: connection_started(generate_connection())

  def connection_started(connection = %Connection{}),
    do: ConnectionStartedEvent.new(connection)

  def connection_closed,
    do: connection_closed(generate_connection())

  def connection_closed(connection = %Connection{}, opts \\ []) do
    reason = Keyword.get(opts, :reason, :normal)

    connection
    |> ConnectionClosedEvent.new(reason)
  end

  defp generate_connection do
    {connection, _} = NetworkSetup.connection()
    connection
  end
end
