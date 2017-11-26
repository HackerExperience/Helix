defmodule Helix.Server.Make.Server do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Model.Server

  @spec desktop(Entity.t) ::
    Server.t
  def desktop(entity = %Entity{}),
    do: server(entity, :desktop)

  @spec npc(Entity.t) ::
    Server.t
  def npc(entity = %Entity{}),
    do: server(entity, :npc)

  @spec server(Entity.t, Server.type) ::
    Server.t
  defp server(entity = %Entity{}, type) do
    relay = nil

    # Setup mobo. TODO: Custom hardware for NPC
    {:ok, _, mobo} = MotherboardFlow.initial_hardware(entity, relay)

    {:ok, server} = ServerFlow.setup(type, entity, mobo, relay)
    server
  end
end
