defmodule Helix.Test.Process.Setup do

  alias Helix.Process.Internal.Process, as: ProcessInternal
  alias Helix.Process.Model.Process

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Process.Data.Setup, as: ProcessDataSetup
  alias Helix.Test.Process.Helper, as: ProcessHelper

  @internet_id NetworkHelper.internet_id()

  def process(opts \\ []) do
    {_, related = %{params: params}} = fake_process(opts)
    {:ok, inserted} = ProcessInternal.create(params)
    {inserted, related}
  end

  @doc """
  NOTE: for a fully integrated process, it's a better idea to use the higher
  level flow setup. For instance, for a BankTransfer process, use
  `BankSetup.transfer_flow`.

  Opts:
  - gateway_id:
  - target_id:
  - entity_id: source entity id.
  - src_file_id:
  - tgt_file_id:
  - network_id:
  - src_connection_id:
  - tgt_connection_id:
  - tgt_log_id:
  - single_server:
  - type: Set process type. If not specified, a random one is generated.
  - data: Data for that specific process type. Ignored if `type` is not set.

  Related: source_entity_id :: Entity.id, target_entity_id :: Entity.id
  """
  def fake_process(opts \\ []) do
    gateway_id = Keyword.get(opts, :gateway_id, ServerHelper.id())
    source_entity_id = Keyword.get(opts, :entity_id, EntityHelper.id())
    {target_id, target_entity_id} =
      cond do
        opts[:single_server] ->
          {gateway_id, source_entity_id}
        opts[:target_id] ->
          {opts[:target_id], nil}
        true ->
          {ServerHelper.id(), EntityHelper.id()}
      end

    src_file_id = Keyword.get(opts, :src_file_id, nil)
    tgt_file_id = Keyword.get(opts, :tgt_file_id, nil)
    src_connection_id = Keyword.get(opts, :src_connection_id, nil)
    tgt_connection_id = Keyword.get(opts, :tgt_connection_id, nil)
    tgt_log_id = Keyword.get(opts, :tgt_log_id, nil)
    network_id = Keyword.get(opts, :network_id, @internet_id)

    meta = %{
      source_entity_id: source_entity_id,
      gateway_id: gateway_id,
      target_entity_id: target_entity_id,
      target_id: target_id,
      src_file_id: src_file_id,
      tgt_file_id: tgt_file_id,
      src_connection_id: src_connection_id,
      tgt_connection_id: tgt_connection_id,
      tgt_log_id: tgt_log_id,
      network_id: network_id
    }

    {process_type, process_data, meta, resources} =
      if opts[:type] do
        ProcessDataSetup.custom(opts[:type], opts[:data] || [], meta)
      else
        ProcessDataSetup.random(meta)
      end

    l_limit = Keyword.get(opts, :l_limit, %{})
    r_limit = Keyword.get(opts, :r_limit, %{})

    static = Keyword.get(opts, :static, resources.static)

    objective = Keyword.get(opts, :objective, resources.objective)

    params = %{
      data: process_data,
      type: process_type,
      gateway_id: meta.gateway_id,
      source_entity_id: meta.source_entity_id,
      target_id: meta.target_id,
      src_file_id: meta.src_file_id,
      tgt_file_id: meta.tgt_file_id,
      network_id: meta.network_id,
      src_connection_id: meta.src_connection_id,
      tgt_connection_id: meta.tgt_connection_id,
      tgt_log_id: meta.tgt_log_id,
      static: static,
      l_limit: l_limit,
      r_limit: r_limit,
      l_dynamic: resources.l_dynamic,
      r_dynamic: resources.r_dynamic,
      objective: objective
    }

    process =
      params
      |> Process.create_changeset()
      |> Ecto.Changeset.apply_changes()
      |> Map.replace(:process_id, ProcessHelper.id())

    related = %{
      source_entity_id: source_entity_id,
      target_entity_id: target_entity_id,
      params: params
    }

    {process, related}
  end

  def fake_process!(opts) do
    {process, _} = fake_process(opts)
    process
  end
end
