defmodule Helix.Network.Internal.Web do

  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Network.Internal.Web.Player, as: WebPlayerInternal
  alias Helix.Network.Internal.Web.NPC, as: WebNPCInternal
  alias Helix.Network.Repo

  def serve(ip, entity) do
    case entity.entity_type do
      :npc ->
        {:npc, serve_npc(ip, entity.entity_id)}
      _ ->
        {:vpc, serve_vpc(ip)}
    end
  end

  defp serve_vpc(ip) do
    # WebPlayerInternal.get_content()
  end

  defp serve_npc(ip, npc_id) do
    npc = NPCQuery.fetch(npc_id)
    WebNPCInternal.get_content(ip, npc)
  end

end
