defmodule Helix.Network.Action.DNS do

  alias HELL.IPv4
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.DNS.Anycast
  alias Helix.Network.Model.DNS.Unicast

  @spec register_unicast(Network.id, String.t, IPv4.t) ::
    {:ok, Unicast.t}
    | {:error, Ecto.Changeset.t}
  def register_unicast(network, name, ip) do
    DNSInternal.register_unicast(%{network_id: network, name: name, ip: ip})
  end

  @spec deregister_unicast(Network.id, String.t) ::
    :ok
  def deregister_unicast(network, name),
    do: DNSInternal.deregister_unicast(network, name)

  @spec register_anycast(String.t, NPC.id) ::
    {:ok, Anycast.t}
    | {:error, Ecto.Changeset.t}
  def register_anycast(name, npc_id) do
    if NPCQuery.fetch(npc_id) do
      DNSInternal.register_anycast(%{name: name, npc_id: npc_id})
    else
      {:error, :invalid_npc}
    end
  end

  @spec deregister_anycast(String.t) ::
    :ok
  def deregister_anycast(name),
    do: DNSInternal.deregister_anycast(name)
end
