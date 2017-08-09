defmodule Helix.Network.Internal.Web do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Model.Network

  @spec serve(Network.idtb, IPv4.t) ::
    {:ok, term}
    | :notfound
  def serve(network, ip) do
    case CacheQuery.from_nip_get_web(network, ip) do
      {:ok, content} ->
        {:ok, content}
      _ ->
        :notfound
    end
  end
end
