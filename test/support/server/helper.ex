defmodule Helix.Test.Server.Helper do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

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

  # HACK
  # This is a giant hack because the current Hardware service lacks the proper
  # API. It will probably be my next PR....
  def update_server_specs(
    server = %Server{},
    %{cpu: cpu, ram: ram, dlk: dlk, ulk: ulk})
  do

  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Repo, as: HardwareRepo

  components =
    server.motherboard_id
    |> MotherboardQuery.fetch()
    |> MotherboardInternal.get_components_ids()

  [comp_cpu] = MotherboardInternal.get_cpus_from_ids(components)
  [comp_ram] = MotherboardInternal.get_rams_from_ids(components)
  [comp_nic] = MotherboardInternal.get_nics_from_ids(components)

  comp_cpu
  |> Ecto.Changeset.change()
  |> Ecto.Changeset.put_change(:clock, cpu)
  |> HardwareRepo.update()

  comp_ram
  |> Ecto.Changeset.change()
  |> Ecto.Changeset.put_change(:ram_size, ram)
  |> HardwareRepo.update()

  nc = comp_nic.network_connection

  nc
  |> Ecto.Changeset.change()
  |> Ecto.Changeset.put_change(:downlink, dlk)
  |> Ecto.Changeset.put_change(:uplink, ulk)
  |> HardwareRepo.update()
  end
end
