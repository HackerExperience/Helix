defmodule Helix.Test.Process.Setup do

  alias Helix.Software.Model.Software.Cracker.Bruteforce,
    as: CrackerBruteforce
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo, as: ProcessRepo

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet NetworkHelper.internet_id()

  def process(opts \\ []) do
    {process, related} = fake_process(opts)
    {:ok, inserted} = ProcessRepo.insert(process)
    {inserted, related}
  end

  @doc """
  Note: for a fully integrated process, it's a better idea to use the higher
  level flow setup. For instance, for a BankTransfer process, use
  `BankSetup.transfer_flow`.

  Opts:
  - gateway_id:
  - target_server_id:
  - file_id:
  - network_id:
  - connection_id:
  - single_server:
  - fake_server: Whether to generate the related servers. Defaults to false.
  """
  def fake_process(opts \\ []) do
    gateway_id = Access.get(opts, :gateway_id, ServerSetup.id())
    gateway_entity_id = Access.get(opts, :entity_id, EntitySetup.id())
    {target_server_id, target_entity_id} =
      cond do
        opts[:single_server] ->
          {gateway_id, gateway_entity_id}
        opts[:target_server_id] ->
          {opts[:target_server_id], nil}
        true ->
          {ServerSetup.id(), EntitySetup.id()}
      end

    file_id = Access.get(opts, :file_id, nil)
    connection_id = Access.get(opts, :connection_id, nil)
    network_id = Access.get(opts, :network_id, @internet)

    {process_type, process_data} = random_process_data()

    params = %{
      process_data: process_data,
      process_type: process_type,
      gateway_id: gateway_id,
      target_server_id: target_server_id,
      file_id: file_id,
      network_id: network_id,
      connection_id: connection_id
    }

    process =
      params
      |> Process.create_changeset()
      |> Ecto.Changeset.apply_changes()
      |> Map.replace(:process_id, Process.ID.generate())

    related = %{
      gateway_entity_id: gateway_entity_id,
      target_entity_id: target_entity_id
    }

    {process, related}
  end

  # Proper random implementation is TODO
  defp random_process_data do
    data = %CrackerBruteforce{
      source_entity_id: EntitySetup.id(),
      network_id: @internet,
      target_server_id: ServerSetup.id(),
      target_server_ip: "9.9.9.9",
      software_version: 10
    }

    {"cracker_bruteforce", data}
  end

  def bruteforce_flow do

    alias Helix.Cache.Query.Cache, as: CacheQuery
    alias Helix.Software.Action.Flow.File.Cracker, as: CrackerFlow
    alias Helix.Test.Software.Setup, as: SoftwareSetup
    {source_server, %{entity: source_entity}} = ServerSetup.server()
    {target_server, _} = ServerSetup.server()

    {:ok, [target_nip]} =
      CacheQuery.from_server_get_nips(target_server.server_id)

    {file, _} =
      SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

    params = %{
      source_entity_id: source_entity.entity_id,
      target_server_id: target_server.server_id,
      network_id: target_nip.network_id,
      target_server_ip: target_nip.ip
    }

    meta = %{
      bounces: []
    }

    {:ok, process} =
      CrackerFlow.execute_cracker(file, source_server, params, meta)

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
