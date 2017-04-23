defmodule Helix.Log.Service.API.Log do
  @moduledoc """
  Functions to work with in-game logs

  An in-game log is a record registering an action done by an entity on a
  server.

  It can be forged and recovered to a previous state.

  It's forging mechanics is implemented as an stack where the last revision is
  the currently displayed message and to see the original log all revisions must
  be recovered.

  Note that on Log context _forging_ and _revising_ are used interchangeably and
  means changing the current message of a log by adding a (forged) revision to
  it's stack.
  """

  alias Ecto.Multi
  alias Helix.Event
  alias Helix.Log.Controller.Log, as: LogController
  alias Helix.Log.Model.Log
  alias Helix.Log.Repo

  @type server_id :: LogController.server_id
  @type entity_id :: LogController.entity_id

  @spec create(server_id, entity_id, String.t) ::
    {:ok, %{log: Log.t, log_touch: any, events: [Event.t]}}
    | {:error, :log | :log_touch, Ecto.Changeset.t, map}
  @doc """
  Creates a new log linked to `entity` on `server` with `message` as content.
  """
  def create(server, entity, message) do
    {multi, events} = LogController.create(server, entity, message)

    multi
    |> Multi.run(:events, fn _ -> {:ok, events} end)
    |> Repo.transaction()
  end

  @spec revise(Log.t, entity_id, String.t, pos_integer) ::
    {:ok, %{revision: any, log_touch: any, events: [Event.t]}}
    | {:error, :revision | :log_touch, Ecto.Changeset.t, map}
  @doc """
  Adds a revision over `log`.

  `entity` is the ID of the entity that is doing the revision, `message` is the
  new log's content and `forge_version` is the version of log forger used to
  make this revision.
  """
  def revise(log, entity, message, forge_version) do
    {multi, events} = LogController.revise(log, entity, message, forge_version)

    multi
    |> Multi.run(:events, fn _ -> {:ok, events} end)
    |> Repo.transaction()
  end

  @spec recover(Log.t) ::
    {:ok, %{log: any, events: [Event.t]}}
    | {:error, :log, :original_revision | Ecto.Changeset.t, map}
  @doc """
  Recovers `log` to a previous revision.

  If the log is in it's original state and it is not a forged log, the operation
  will fail; if the log is in it's original state and it's forged, it will be
  deleted; otherwise the revision will be deleted and the log will be updated to
  use the last revision's message.
  """
  def recover(log) do
    multi = LogController.recover(log)

    multi
    |> Multi.run(:events, fn %{log: {:event, events}} ->
      {:ok, events}
    end)
    |> Repo.transaction()
  end

  @spec fetch(Log.id) ::
    Log.t
    | nil
  @doc """
  Fetches a log
  """
  def fetch(id),
    do: Repo.one(LogController.fetch(id))

  @spec hard_delete(Log.t) ::
    {:ok, Log.t}
    | {:error, reason :: term}
  @doc """
  Deletes the log by removing it's entry from database
  """
  def hard_delete(log),
    do: Repo.delete(log)

  @spec get_logs_on_server(server_id, Keyword.t) ::
    [Log.t]
  @doc """
  Fetches logs on `server`
  """
  def get_logs_on_server(server, params \\ []) do
    server
    |> LogController.get_logs_on_server(params)
    |> Repo.all()
  end

  @spec get_logs_from_entity_on_server(server_id, entity_id, Keyword.t) ::
    [Log.t]
  @doc """
  Fetches logs on `server` that `entity` has created or revised
  """
  def get_logs_from_entity_on_server(server, entity, params \\ []) do
    server
    |> LogController.get_logs_from_entity_on_server(entity, params)
    |> Repo.all()
  end
end
