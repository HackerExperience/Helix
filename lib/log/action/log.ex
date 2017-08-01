defmodule Helix.Log.Action.Log do
  @moduledoc """
  Functions to work with in-game logs

  An in-game log is a record registering an action done by an entity on a
  server.

  It can be forged and recovered to a previous state.

  Its forging mechanics is implemented as an stack where the last revision is
  the currently displayed message and to see the original log all revisions must
  be recovered.

  Note that on Log context _forging_ and _revising_ are used interchangeably and
  means changing the current message of a log by adding a (forged) revision to
  it's stack.
  """

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Model.Log
  alias Helix.Log.Repo

  alias Helix.Log.Model.Log.LogCreatedEvent
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent

  @spec create(Server.t | Server.id, Entity.t | Entity.id, String.t) ::
    {:ok, Log.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a new log linked to `entity` on `server` with `message` as content.
  """
  def create(server, entity, message) do
    with {:ok, log} <- LogInternal.create(server, entity, message) do
      Event.emit(%LogCreatedEvent{server_id: log.server_id})

      {:ok, log}
    end
  end

  @spec revise(log, Entity.t | Entity.id, String.t, pos_integer) ::
    {:ok, log}
    | {:error, Ecto.Changeset.t} when log: Log.t
  @doc """
  Adds a revision over `log`.

  `entity` is the ID of the entity that is doing the revision, `message` is the
  new log's content and `forge_version` is the version of log forger used to
  make this revision.
  """
  def revise(log, entity, message, forge_version) do
    with \
      {:ok, ^log} <- LogInternal.revise(log, entity, message, forge_version)
    do
      Event.emit(%LogModifiedEvent{server_id: log.server_id})

      {:ok, log}
    end
  end

  @spec recover(Log.t) ::
    {:ok, :deleted | :recovered}
    | {:error, :original_revision}
  @doc """
  Recovers `log` to a previous revision.

  If the log is in it's original state and it is not a forged log, the operation
  will fail; if the log is in it's original state and it's forged, it will be
  deleted; otherwise the revision will be deleted and the log will be updated to
  use the last revision's message.
  """
  def recover(log) do
    case LogInternal.recover(log) do
      {:ok, :deleted} ->
        Event.emit(%LogDeletedEvent{server_id: log.server_id})
        {:ok, :deleted}
      {:ok, :recovered} ->
        Event.emit(%LogModifiedEvent{server_id: log.server_id})
        {:ok, :recovered}
      {:error, :original_revision} ->
        {:error, :original_revision}
    end
  end

  @spec hard_delete(Log.t) ::
    {:ok, Log.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Deletes the log by removing its entry from database
  """
  def hard_delete(log),
    do: Repo.delete(log)
end
