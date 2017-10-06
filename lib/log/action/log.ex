defmodule Helix.Log.Action.Log do
  @moduledoc """
  Functions to work with in-game logs.

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

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Model.Log

  alias Helix.Log.Event.Log.Created, as: LogCreatedEvent
  alias Helix.Log.Event.Log.Deleted, as: LogDeletedEvent
  alias Helix.Log.Event.Log.Modified, as: LogModifiedEvent

  @spec create(Server.idt, Entity.idt, String.t, pos_integer | nil) ::
    {:ok, Log.t, [LogCreatedEvent.t]}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a new log linked to `entity` on `server` with `message` as content.
  """
  def create(server, entity, message, forge \\ nil) do
    with {:ok, log} <- LogInternal.create(server, entity, message, forge) do
      event = LogCreatedEvent.new(log)

      {:ok, log, [event]}
    end
  end

  @spec revise(Log.t, Entity.idt, String.t, pos_integer) ::
    {:ok, Log.t, [LogModifiedEvent.t]}
    | {:error, Ecto.Changeset.t}
  @doc """
  Adds a revision over `log`.

  ### Params
  - `entity` is the the entity that is doing the revision.
  - `message` is the new log's content.
  - `forge_version` is the version of log forger used to make this revision.

  ### Examples

      iex> revise(%Log{}, %Entity{}, "empty log", 100)
      {:ok, %Log{message: "empty log"}, [%LogModifiedEvent{}]}
  """
  def revise(log, entity, message, forge_version) do
    with \
      {:ok, log} <- LogInternal.revise(log, entity, message, forge_version)
    do
      event = LogModifiedEvent.new(log)

      {:ok, log, [event]}
    end
  end

  @spec recover(Log.t) ::
    {:ok, :recovered, [LogModifiedEvent.t]}
    | {:ok, :deleted, [LogDeletedEvent.t]}
    | {:error, :original_revision}
  @doc """
  Recovers `log` to a previous revision.

  ### Notes
  - If the log is in its original state and it is not a forged log, the
  operation will fail with `{:error, :original_revision}`.
  - If the log is in its original state and it is forged, it will be deleted,
  returning `{:ok, :deleted, [Helix.Event.t]}`.
  - Otherwise the revision will be deleted and the log will be updated to use
  the last revision's message, returning `{:ok, :recovered, [Helix.Event.t]}`.
  """
  def recover(log) do
    case LogInternal.recover(log) do
      {:ok, :deleted} ->
        event = LogDeletedEvent.new(log)
        {:ok, :deleted, [event]}

      {:ok, :recovered} ->
        event = LogModifiedEvent.new(log)
        {:ok, :recovered, [event]}

      {:error, :original_revision} ->
        {:error, :original_revision}
    end
  end
end
