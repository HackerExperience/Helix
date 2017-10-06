defmodule Helix.Test.Software.Setup.Flow do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow
  alias Helix.Software.Action.Flow.Software.Cracker, as: CrackerFlow
  alias Helix.Software.Query.Storage, as: StorageQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  def file_transfer(type) do
    {gateway, _} = ServerSetup.server()
    {file, %{server_id: destination_id}} = SoftwareSetup.file()

    destination_server =
      if type == :upload do
        destination_id
      else
        gateway.server_id
      end

    destination_storage =
      destination_server
      |> CacheQuery.from_server_get_storages()
      |> elem(1)
      |> List.first()
      |> StorageQuery.fetch()

    network_info = %{
      gateway_id: gateway.server_id,
      destination_id: destination_id,
      network_id: NetworkHelper.internet(),
      bounces: [],
      tunnel: nil
    }

    {:ok, process} =
      FileTransferFlow.transfer(
        type,
        file,
        destination_storage,
        network_info
      )

    {process, %{}}
  end

  def bruteforce do
    {source_server, %{entity: source_entity}} = ServerSetup.server()
    {target_server, _} = ServerSetup.server()

    {:ok, [target_nip]} =
      CacheQuery.from_server_get_nips(target_server.server_id)

    {file, _} =
      SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

    params = %{
      target_server_id: target_server.server_id,
      network_id: target_nip.network_id,
      target_server_ip: target_nip.ip
    }

    meta = %{
      bounces: []
    }

    {:ok, process} =
      CrackerFlow.execute_cracker(file, source_server.server_id, params, meta)

    related = %{
      source_server: source_server,
      source_entity: source_entity,
      target_server: target_server,
      target_ip: target_nip.ip,
      network_id: target_nip.network_id
    }

    {process, related}
  end
end
