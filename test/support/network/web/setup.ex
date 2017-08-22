defmodule Helix.Test.Network.Web.Setup do

  alias Helix.Universe.NPC.Internal.Web, as: NPCWebInternal
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper

  def npc(npc_id, npc_ip) do
    npc = NPCQuery.fetch(npc_id)

    NPCWebInternal.generate_content(npc, NetworkHelper.internet_id(), npc_ip)
  end

end
