defmodule Helix.Server.State.Supervisor do

  use Supervisor

  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(ServerWebsocketChannelState, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
