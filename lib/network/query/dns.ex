defmodule Helix.Network.Query.DNS do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Network.Internal.DNS, as: DNSInternal

  @spec resolve(String.t, HELL.IPv4.t) ::
    {:ok, HELL.IPv4.t}
    | :nxdomain
  @doc """
  DNS resolution function.

  It first looks for any Unicast entry. If none are found, it looks for Anycast.
  If an Anycast entry is found, it then proceeds to calculate the nearest NPC
  entry to the source connection.
  If neither Unicast or Anycast entries are found, it returns :nxdomain
  """
  def resolve(name, origin) do
    cond do
      unicast = DNSInternal.lookup_unicast(name) ->
        {:ok, unicast.ip}

      anycast = DNSInternal.lookup_anycast(name) ->
        {:ok, nearest_server(anycast.npc_id, origin)}

      true ->
        :nxdomain
    end
  end

  @spec nearest_server(HELL.PK.t, IPv4.t) :: IPv4.t
  defp nearest_server(npc_id, origin_server) do
    # TODO: Actual GIS implementation. Move to `GIS` module
    # TODO: Network handling
    EntityQuery.get_servers_from_entity(%Entity{entity_id: npc_id})
    |> List.first()
    |> ServerQuery.get_ip("::")
  end
end
