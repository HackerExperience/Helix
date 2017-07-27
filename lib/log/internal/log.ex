defmodule Helix.Log.Internal.Log do
  @moduledoc false

  alias Ecto.Multi
  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Log.LogCreatedEvent
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent
  alias Helix.Log.Model.LogTouch
  alias Helix.Log.Model.Revision
  alias Helix.Log.Repo

  @spec fetch(Log.id) ::
    Log.t
    | nil
  def fetch(log_id) do
    log_id
    |> Log.Query.by_log()
    |> Repo.one()
  end

  @spec get_logs_on_server(Server.t | Server.id, Keyword.t) ::
    [Log.t]
  def get_logs_on_server(server, _params \\ []) do
    server
    |> Log.Query.by_server()
    # TODO: Use id's timestamp
    |> Log.Query.order_by_newest()
    |> Repo.all()
  end

  @spec get_logs_from_entity_on_server(Server.t | Server.id, Entity.t | Entity.id, Keyword.t) ::
    [Log.t]
  def get_logs_from_entity_on_server(server, entity, _params \\ []) do
    server
    |> Log.Query.by_server()
    # TODO: Use id's timestamp
    |> Log.Query.order_by_newest()
    |> Log.Query.edited_by_entity(entity)
    |> Repo.all()
  end

  @spec create(Server.id, Entity.id, String.t, pos_integer | nil) ::
    {Multi.t, [Event.t]}
  def create(server, entity, message, forge_version \\ nil) do
    params = %{
      server_id: server,
      entity_id: entity,
      message: message,
      forge_version: forge_version
    }

    multi =
      Multi.new()
      |> Multi.insert(:log, Log.create_changeset(params))
      |> Multi.run(:log_touch, fn %{log: log} ->
      log
      |> LogTouch.create(entity)
      |> Repo.insert()
    end)

      events = [%LogCreatedEvent{server_id: server}]

      {multi, events}
  end

  @spec revise(Log.t, Entity.id, String.t, pos_integer) ::
    {Multi.t, [Event.t]}
  def revise(log, entity, message, forge_version) do
    revision = Revision.create(log, entity, message, forge_version)

    multi =
      Multi.new()
      |> Multi.insert(:revision, revision)
      |> Multi.run(:log_touch, fn _ ->
        log
        |> LogTouch.create(entity)
        |> Repo.insert(on_conflict: :nothing)
      end)

    events = [%LogModifiedEvent{server_id: log.server_id}]

    {multi, events}
  end

  @spec recover(Log.t) ::
    Multi.t
  def recover(log) do
    Multi.new()
    |> Multi.run(:log, fn _ ->
      query =
        Revision
        |> Revision.Query.from_log(log)
        |> Revision.Query.last(2)

      case Repo.all(query) do
        [%{forge_version: nil}] ->
          {:error, :original_revision}

        [_] ->
          # Forged log, should be deleted
          with {:ok, _} <- Repo.delete(log) do
            events = [%LogDeletedEvent{server_id: log.server_id}]
            {:ok, {:event, events}}
          end

        [old, %{message: m}] ->
          with \
            {:ok, _} <- Repo.delete(old),
            changeset = Log.update_changeset(log, %{message: m}),
            {:ok, _} <- Repo.update(changeset)
          do
            events = [%LogModifiedEvent{server_id: log.server_id}]
            {:ok, {:event, events}}
          end
      end
    end)
  end
end
