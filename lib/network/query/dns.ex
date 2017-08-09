defmodule Helix.Network.Query.DNS do

  alias HELL.IPv4
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Network.Model.Network

  @spec resolve(Network.idtb, String.t, IPv4.t) ::
    {:ok, IPv4.t}
    | :nxdomain
  @doc """
  DNS resolution function.

  It first looks for any Unicast entry. If none are found, it looks for Anycast.
  If an Anycast entry is found, it then proceeds to calculate the nearest NPC
  entry to the source connection.
  If neither Unicast or Anycast entries are found, it returns :nxdomain
  """
  def resolve(network, name, origin) do
    cond do
      unicast = DNSInternal.lookup_unicast(network, name) ->
        {:ok, unicast.ip}

      anycast = DNSInternal.lookup_anycast(name) ->
        {:ok, nearest_server(network, anycast.npc_id, origin)}

      true ->
        :nxdomain
    end
  end

  @spec nearest_server(Network.idtb, NPC.id, IPv4.t) ::
    IPv4.t
    | nil
  defp nearest_server(network, npc_id, _origin_server) do
    # TODO: Actual GIS implementation. Move to `GIS` module
    npc_id
    |> NPCQuery.fetch()
    |> EntityQuery.get_entity_id()
    |> EntityQuery.fetch()
    |> EntityQuery.get_servers()
    |> List.first()
    |> ServerQuery.get_ip(network)
  end
end
