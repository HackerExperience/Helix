defmodule Helix.Network.Action.DNS do

  alias HELL.IPv4
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.DNS.Anycast
  alias Helix.Network.Model.DNS.Unicast

  @spec register_unicast(Network.idt, String.t, IPv4.t) ::
    {:ok, Unicast.t}
    | {:error, Ecto.Changeset.t}
  def register_unicast(network, name, ip) do
    DNSInternal.register_unicast(%{network_id: network, name: name, ip: ip})
  end

  @spec deregister_unicast(Network.idt, String.t) ::
    :ok
  def deregister_unicast(network, name),
    do: DNSInternal.deregister_unicast(network, name)

  @spec register_anycast(String.t, NPC.idt) ::
    {:ok, Anycast.t}
    | {:error, Ecto.Changeset.t}
  def register_anycast(name, npc = %NPC{}),
    do: register_anycast(name, npc.npc_id)
  def register_anycast(name, npc_id = %NPC.ID{}),
    do: DNSInternal.register_anycast(%{name: name, npc_id: npc_id})

  @spec deregister_anycast(String.t) ::
    :ok
  def deregister_anycast(name),
    do: DNSInternal.deregister_anycast(name)
end
