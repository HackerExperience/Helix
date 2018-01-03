defmodule Helix.Story.Make.Story do

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Server

  alias Helix.Universe.NPC.Make.NPC, as: MakeNPC
  alias Helix.Entity.Make.Entity, as: MakeEntity
  alias Helix.Server.Make.Server, as: MakeServer

  @typep char_related :: %{entity: Entity.t}

  @spec char(Network.id) ::
    {:ok, Server.t, char_related}
  def char(network_id = %Network.ID{}) do
    network = NetworkQuery.fetch(network_id)
    net_data =
      %{
        network: network,
        ip: IPv4.autogenerate(),
        speed: %{dlk: 128, ulk: 64}
      }

    with \
      {:ok, npc, _} <- MakeNPC.story_char(),
      {:ok, entity, _} <- MakeEntity.entity(npc),
      {:ok, server, _} <- MakeServer.npc(entity, net_data)
    do
      {:ok, server, %{entity: entity}}
    end
  end
end
