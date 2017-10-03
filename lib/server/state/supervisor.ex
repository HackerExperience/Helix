defmodule Helix.Server.State.Supervisor do

  use Supervisor

  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState
  alias Helix.Server.State.Websocket.GC, as: ServerWebsocketGC

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(ServerWebsocketChannelState, []),
      worker(ServerWebsocketGC, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
