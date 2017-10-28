defmodule Helix.Test.Process.Setup do

  alias Helix.Process.Internal.Process, as: ProcessInternal
  alias Helix.Process.Model.Process

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Data.Setup, as: ProcessDataSetup

  @internet NetworkHelper.internet_id()

  def process(opts \\ []) do
    {_, related = %{params: params}} = fake_process(opts)
    {:ok, inserted} = ProcessInternal.create(params)
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
  - type: Set process type. If not specified, a random one is generated.
  - data: Data for that specific process type. Ignored if `type` is not set.

  Related: source_entity_id :: Entity.id, target_entity_id :: Entity.id
  """
  def fake_process(opts \\ []) do
    gateway_id = Keyword.get(opts, :gateway_id, ServerSetup.id())
    source_entity_id = Keyword.get(opts, :entity_id, EntitySetup.id())
    {target_server_id, target_entity_id} =
      cond do
        opts[:single_server] ->
          {gateway_id, source_entity_id}
        opts[:target_server_id] ->
          {opts[:target_server_id], nil}
        true ->
          {ServerSetup.id(), EntitySetup.id()}
      end

    file_id = Keyword.get(opts, :file_id, nil)
    connection_id = Keyword.get(opts, :connection_id, nil)
    network_id = Keyword.get(opts, :network_id, @internet)

    dynamic = Keyword.get(opts, :dynamic, [:cpu, :ram])

    meta = %{
      source_entity_id: source_entity_id,
      gateway_id: gateway_id,
      target_entity_id: target_entity_id,
      target_server_id: target_server_id,
      file_id: file_id,
      connection_id: connection_id,
      network_id: network_id
    }

    {process_type, process_data, meta, resources} =
      if opts[:type] do
        ProcessDataSetup.custom(opts[:type], opts[:data] || [], meta)
      else
        ProcessDataSetup.random(meta)
      end

    params = %{
      data: process_data,
      type: process_type,
      gateway_id: meta.gateway_id,
      source_entity_id: meta.source_entity_id,
      target_id: meta.target_server_id,
      file_id: meta.file_id,
      network_id: meta.network_id,
      connection_id: meta.connection_id,
      static: resources.static,
      dynamic: resources.dynamic,
      objective: resources.objective
    }

    process =
      params
      |> Process.create_changeset()
      |> Ecto.Changeset.apply_changes()
      |> Map.replace(:process_id, Process.ID.generate())

    related = %{
      source_entity_id: source_entity_id,
      target_entity_id: target_entity_id,
      params: params
    }

    {process, related}
  end
end
