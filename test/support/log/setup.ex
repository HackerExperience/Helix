defmodule Helix.Test.Log.Setup do

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Log.Model.Log
  alias Helix.Log.Internal.Log, as: LogInternal

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Log.Helper, as: LogHelper

  @doc """
  See doc on `fake_log/1`
  """
  def log(opts \\ []) do
    {_, related = %{params: params}} = fake_log(opts)
    {:ok, inserted} =
      LogInternal.create(
        params.server_id,
        params.entity_id,
        params.message,
        params.forge_version
      )

    {inserted, related}
  end

  def log!(opts \\ []) do
    {log, _} = log(opts)
    log
  end

  @doc """
  - server_id: Server which that log belongs to.
  - entity_id: Entity which that log belongs to.
  - message: Log message.
  - forge_version: Set the forge version. Defaults to nil.
  - fake_server: Whether the Server that hosts the log should be generated.
    Defaults to false.
  - fake_entity: Whether the Entity that owns the log should be generated.
    Defaults to true.
  - own_log: Whether the generated log should belong to entity who owns that
    server. Defaults to false.

  Related: Log.creation_params, Server.t, Entity.id, message :: String.t
  """
  def fake_log(opts \\ []) do
    if opts[:own_log] == true and opts[:fake_server] == true do
      raise "Can't set both `own_log` and `fake_server`"
    end

    # Makes credo happy...
    {server, entity_id, message, forge_version} = fake_log_get_data(opts)

    params = %{
      server_id: server.server_id,
      entity_id: entity_id,
      message: message,
      forge_version: forge_version
    }

    changeset = Log.create_changeset(params)
    log =
      changeset
      |> Ecto.Changeset.apply_changes()
      |> Map.replace(:creation_time, DateTime.utc_now())
      |> Map.replace(:log_id, LogHelper.id())

    related = %{
      params: params,
      server: server,
      entity_id: entity_id,
      message: message,
      changeset: changeset
    }

    {log, related}
  end

  defp fake_log_get_data(opts) do
    {server, server_owner} =
      cond do
        # User asked for fake server
        opts[:fake_server] ->
          {server, _} = ServerSetup.fake_server()

          {server, nil}

        # User specified a server_id (must exist on the DB)
        opts[:server_id] ->
          server = ServerQuery.fetch(opts[:server_id])
          entity = EntityQuery.fetch_by_server(opts[:server_id])

          {server, entity}

        # All else: generate a real server
        true ->
          {server, %{entity: entity}} = ServerSetup.server()

          {server, entity}
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

    message = Access.get(opts, :message, LogHelper.random_message())
    forge_version = Access.get(opts, :forge_version, nil)

    {server, entity_id, message, forge_version}
  end
end
