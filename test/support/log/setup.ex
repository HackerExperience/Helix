defmodule Helix.Test.Log.Setup do

  alias Ecto.Changeset
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Log.Model.Log
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Repo, as: LogRepo

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Log.Helper, as: LogHelper

  @doc """
  See doc on `fake_log/1`
  """
  def log(opts \\ []) do
    {_, related = %{changeset: changeset}} = fake_log(opts)
    {:ok, log} = LogRepo.insert(changeset)

    log =
      if related.revisions > 1 do
        1..(related.revisions - 1)
        |> Enum.reduce(log, fn _, acc ->
          entity_id = EntityHelper.id()
          log_info = LogHelper.log_info()
          forge_version = SoftwareHelper.random_version()

          {:ok, new_log} =
            LogInternal.revise(acc, entity_id, log_info, forge_version)

          new_log
        end)
      else
        log
      end

    {log, related}
  end

  def log!(opts \\ []) do
    {log, _} = log(opts)
    log
  end

  @doc """
  - server_id: Server which that log belongs to.
  - entity_id: Entity which that log belongs to.
  - type: Underlying log type. Defaults to random type.
  - data_opts: Opts that will be used to generate the underlying log data.
  - forge_version: Set the forge version. Defaults to nil.
  - real_server: Whether the Server that hosts the log should be real. Defaults
    to false.
  - fake_entity: Whether the Entity that owns the log should be generated.
    Defaults to true.
  - own_log: Whether the generated log should belong to entity who owns that
    server. Defaults to false.
  - revisions: How many revisions the log should have. Defaults to 1.

  Related: Log.creation_params, Server.t, Entity.id, message :: String.t
  """
  def fake_log(opts \\ []) do
    if opts[:forger_version],
      do: raise "It's `forge_version`"

    # Makes credo happy...
    {server_id, entity_id, {type, data}, forge_version} =
      fake_log_get_data(opts)

    params = %{server_id: server_id}

    revision_params = %{
      entity_id: entity_id,
      forge_version: forge_version,
      type: type,
      data: Map.from_struct(data)
    }

    changeset = Log.create_changeset(params, revision_params)

    log = Changeset.apply_changes(changeset)

    related = %{
      params: params,
      revision_params: revision_params,
      entity_id: entity_id,
      type: type,
      data: data,
      changeset: changeset,
      revisions: Keyword.get(opts, :revisions, 1)
    }

    {log, related}
  end

  defp fake_log_get_data(opts) do
    {server_id, server_owner} =
      cond do
        # User asked for fake server
        opts[:real_server] ->
          {server, %{entity: entity}} = ServerSetup.server()
          {server.server_id, entity}

        # User specified a server_id (must exist on the DB)
        opts[:server_id] ->
          entity_id =
            EntityQuery.fetch_by_server(opts[:server_id])
            || EntityHelper.id()

          {opts[:server_id], entity_id}

        # All else: generate a real server
        true ->
          {ServerHelper.id(), nil}
      end

    entity_id =
      cond do
        # User specified the `entity_id`
        opts[:entity_id] ->
          opts[:entity_id]

        # Generating log for own server
        opts[:own_log] ->
          server_owner.entity_id

        # User asked for real entity
        true == opts[:fake_entity] ->
          EntitySetup.entity!().entity_id

        # All else: generate a fake entity id.
        true ->
          EntityHelper.id()
      end

    log_info = LogHelper.log_info(opts)
    forge_version = Keyword.get(opts, :forge_version, nil)

    {server_id, entity_id, log_info, forge_version}
  end
end
