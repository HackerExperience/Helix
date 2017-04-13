defmodule Helix.Log.Controller.Log do
  @moduledoc false

  alias Ecto.Multi
  alias Ecto.Queryable
  alias Helix.Event
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.LogTouch
  alias Helix.Log.Model.Revision
  alias Helix.Log.Repo

  @type server_id :: HELL.PK.t
  @type entity_id :: HELL.PK.t

  @spec create(server_id, entity_id, String.t, pos_integer | nil) ::
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

    events = []

    {multi, events}
  end

  @spec fetch(Log.id) ::
    Queryable.t
  def fetch(log_id),
    do: Log.Query.by_id(log_id)

  @spec get_logs_on_server(server_id, Keyword.t) ::
    Queryable.t
  def get_logs_on_server(server, _params \\ []) do
    Log
    |> Log.Query.by_server_id(server)
    # TODO: Use id's timestamp
    |> Log.Query.order_by_newest()
  end

  @spec get_logs_from_entity_on_server(server_id, entity_id, Keyword.t) ::
    Queryable.t
  def get_logs_from_entity_on_server(server, entity, _params \\ []) do
    server
    |> get_logs_on_server()
    |> Log.Query.edited_by_entity(entity)
  end

  @spec revise(Log.t, entity_id, String.t, pos_integer) ::
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

    events = []

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
            events = []
            {:ok, {:event, events}}
          end

        [old, %{message: m}] ->
          with \
            {:ok, _} <- Repo.delete(old),
            changeset = Log.update_changeset(log, %{message: m}),
            {:ok, _} <- Repo.update(changeset)
          do
            events = []
            {:ok, {:event, events}}
          end
      end
    end)
  end
end
