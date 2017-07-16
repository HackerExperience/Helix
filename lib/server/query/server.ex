defmodule Helix.Server.Query.Server do

  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Cache.Query.Cache, as: CacheQuery

  @spec fetch(HELL.PK.t) ::
    Server.t
    | nil
  @doc """
  Fetches a server
  """
  def fetch(server_id) do
    ServerInternal.fetch(server_id)
  end

  @spec fetch_by_motherboard(HELL.PK.t) ::
    Server.t
    | nil
  @doc """
  Fetches the server that mounts the `motherboard`
  """
  def fetch_by_motherboard(motherboard) do
    Repo.get_by(Server, motherboard_id: motherboard)
  end

  def fetch_by_nip(network_id, ip) do
    with \
         motherboard_id = MotherboardQuery.fetch_by_nip(network_id, ip),
         true <- not is_nil(motherboard_id),
      server = fetch_by_motherboard(motherboard_id)
    do
    server
    else
      _ ->
        nil
    end
  end

  def get_nips(server_id) do
    {:ok, nips} = CacheQuery.from_server_get_nips(server_id)
    nips
  end

  def get_ip(server_id, network_id) do
    get_nips(server_id)
    |> Enum.find(fn(net) ->
      net.network_id == network_id
      end)
  end

end
