# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Test.Log.Setup do

  alias Ecto.Changeset
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Log.Model.Log
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Repo, as: LogRepo

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup
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
  - log_id: Hardcode the log id. Useful for pagination tests. Optional.
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

    # Override generated `log_id` with custom `log_id` if specified
    changeset =
      if opts[:log_id] do
        log_id = %Log.ID{id: HELL.IPv6.binary_to_address_tuple!(opts[:log_id])}

        revision = Changeset.get_change(changeset, :revision)
        new_revisions =
          changeset
          |> Changeset.get_change(:revisions)
          |> Enum.map(&(Changeset.force_change(&1, :log_id, log_id)))

        changeset
        |> Changeset.force_change(:log_id, log_id)
        |> Changeset.force_change(:revision, Map.put(revision, :log_id, log_id))
        |> Changeset.put_assoc(:revisions, new_revisions)
      else
        changeset
      end

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

  @relay nil

  alias Helix.Log.Action.Flow.Recover, as: LogRecoverFlow

  @doc """
  Starts a LogRecoverProcess.

  Opts:
  - *method: Whether the process is `global` or `custom`. Random otherwise.
  - local?: Whether the process is recovering a log from the same gateway.
    Defaults to random.
  - gateway: Set gateway server. Type: `Server.t`.
  - endpoint: Set endpoint server. Type: `Server.t`.
  - recover: Set recover software. Type: `File.t`.
  - entity_id: Set entity who is performing action. Defaults to *random* entity.
  - conn_info: Conn info ({tunnel, connection}). Defaults to `nil` (local).
  - log: Log to be recovered. Only valid to `custom`.
  """
  def recover_flow(opts \\ []) do
    method = Keyword.get(opts, :method, Enum.random([:global, :custom]))

    if not is_nil(opts[:conn_info]) and opts[:local?] == false,
      do: raise("Can't set both `conn_info` and `local?`. ")

    if method == :global and not is_nil(opts[:log]),
      do: raise("Can't use `global` method with custom `log`")

    local? =
      cond do
        not is_nil(opts[:conn_info]) ->
          false

        not is_nil(opts[:local?]) ->
          opts[:local?]

        true ->
          Random.boolean()
      end

    gateway = Keyword.get(opts, :gateway, ServerSetup.server!())
    entity_id = Keyword.get(opts, :entity_id, EntityHelper.id())

    endpoint =
      if local? do
        gateway
      else
        Keyword.get(opts, :endpoint, ServerSetup.server!())
      end

    recover =
      Keyword.get(
        opts, :recover, SoftwareSetup.log_recover!(server_id: gateway.server_id)
      )

    conn_info =
      if local? do
        nil
      else
        Keyword.get(opts, :conn_info, raise("Remote conn_info is TODO"))
      end

    logs =
      if method == :global do
        total = Keyword.get(opts, :total_logs, 1)

        0..(total - 1)
        |> Enum.reduce([], fn _, acc ->
          [log!(server_id: endpoint.server_id, revisions: 2) | acc]
        end)
      else
        log =
          Keyword.get(
            opts, :log, log!(server_id: endpoint.server_id, revisions: 2)
          )

        [log]
      end

    result =
      if method == :global do
        LogRecoverFlow.global(
          gateway, endpoint, recover, entity_id, conn_info, @relay
        )
      else
        log = Enum.random(logs)

        LogRecoverFlow.custom(
          gateway, endpoint, log, recover, entity_id, conn_info, @relay
        )
      end

    related =
      %{
        gateway: gateway,
        endpoint: endpoint,
        logs: logs,
        entity_id: entity_id,
        method: method,
        recover: recover,
        conn_info: conn_info
      }

    {result, related}
  end
end
