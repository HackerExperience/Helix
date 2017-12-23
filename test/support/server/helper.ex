# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Test.Server.Helper do

  alias Ecto.Changeset
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Internal.Component, as: ComponentInternal
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Server.Repo, as: ServerRepo

  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet NetworkHelper.internet_id()

  def get_ip(server, network_id \\ @internet)
  def get_ip(server = %Server{}, network_id),
    do: get_ip(server.server_id, network_id)
  def get_ip(server_id = %Server.ID{}, network_id),
    do: ServerQuery.get_ip(server_id, network_id)

  def get_owner(server),
    do: EntityQuery.fetch_by_server(server)

  def get_nip(server = %Server{}),
    do: get_nip(server.server_id)
  def get_nip(server_id = %Server.ID{}),
    do: get_all_nips(server_id) |> List.first()

  def get_all_nips(server = %Server{}),
    do: get_all_nips(server.server_id)
  def get_all_nips(server_id = %Server.ID{}),
    do: CacheQuery.from_server_get_nips!(server_id)

  @doc """
  Modify a server's component resources

  NOTE: The method we are using here to update a server's specs works for tests,
  but is not the same one used by the player.
  The player can not modify a given component directly. Instead, he/she must buy
  a new one and attach to the motherboard.
  Within the test context, we can get away with modifying the component directly
  """
  def update_server_specs(server = %Server{}, new) do
    motherboard = server.motherboard_id |> MotherboardQuery.fetch()

    cpu = motherboard |> MotherboardInternal.get_cpus() |> List.first()
    ram = motherboard |> MotherboardInternal.get_rams() |> List.first()
    nic = motherboard |> MotherboardInternal.get_nics() |> List.first()
    hdd = motherboard |> MotherboardInternal.get_hdds() |> List.first()

    if new[:cpu] do
      ComponentInternal.update_custom(cpu, %{clock: new[:cpu]})
    end

    ram_custom =
      %{}
      |> Map.merge(new[:ram_size] && %{size: new[:ram_size]} || %{})
      |> Map.merge(new[:ram_clock] && %{clock: new[:ram_clock]} || %{})

    unless Enum.empty?(ram_custom) do
      ComponentInternal.update_custom(ram, ram_custom)
    end

    hdd_custom =
      %{}
      |> Map.merge(new[:hdd_size] && %{size: new[:hdd_size]} || %{})
      |> Map.merge(new[:hdd_iops] && %{iops: new[:hdd_iops]} || %{})

    unless Enum.empty?(hdd_custom) do
      ComponentInternal.update_custom(hdd, hdd_custom)
    end

    if not is_nil(new[:dlk]) or not is_nil(new[:ulk]) do
      dlk = new[:dlk] || nic.custom.dlk
      ulk = new[:ulk] || nic.custom.ulk

      custom = %{dlk: dlk, ulk: ulk}

      ComponentInternal.update_custom(nic, custom)
    end
  end

  @doc """
  Use this function to modify a server's motherboard type.

  It may receive a component spec_id, in which case the underlying mobo spec is
  changed directly, or a component_id, in which case it is assigned as the new
  mobo. It may also receive `nil`, signaling we should detach the server mobo.

  NOTE: The method used here is not the same one used by the player. Here we are
  modifying the existing mobo directly, while the player would have to buy a new
  one from the store and re-link his existing components.
  For test purposes this is OK, but caveat emptor
  """
  def update_server_mobo(server = %Server{}, nil) do
    server
    |> Server.detach_motherboard()
    |> ServerRepo.update!()
  end

  def update_server_mobo(server = %Server{}, mobo_id = %Component.ID{}) do
    server
    |> Changeset.change()
    |> Changeset.put_change(:motherboard_id, mobo_id)
    |> ServerRepo.update!()
  end

  def update_server_mobo(server = %Server{}, spec_id) when is_atom(spec_id) do
    mobo = ComponentInternal.fetch(server.motherboard_id)

    mobo
    |> Changeset.change()
    |> Changeset.put_change(:spec_id, spec_id)
    |> ServerRepo.update!()
  end

  def update_server_mobo(s_id = %Server.ID{}, spec_id) when is_atom(spec_id) do
    s_id
    |> ServerQuery.fetch()
    |> update_server_mobo(spec_id)
  end
end
