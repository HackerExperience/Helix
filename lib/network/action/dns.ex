defmodule Helix.Network.Action.DNS do

  alias Helix.Network.Model.DNS.Unicast
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery

  def register_unicast(name, ip) do
    DNSInternal.register_unicast(%{name: name, ip: ip})
  end

  def deregister_unicast(name),
    do: DNSInternal.deregister_unicast(name)

  def register_anycast(name, npc_id) do
    case NPCQuery.fetch(npc_id) do
      nil ->
        {:error, :invalid_npc}
      npc ->
        DNSInternal.register_anycast(%{name: name, npc_id: npc_id})
    end
  end

  def deregister_anycast(name),
    do: DNSInternal.deregister_anycast(name)
end
