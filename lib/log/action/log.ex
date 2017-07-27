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

  alias Ecto.Multi
  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Model.Log
  alias Helix.Log.Repo

  @spec create(Server.id, Entity.id, String.t) ::
    {:ok, %{log: Log.t, log_touch: any, events: [Event.t]}}
    | {:error, :log | :log_touch, Ecto.Changeset.t, map}
  @doc """
  Creates a new log linked to `entity` on `server` with `message` as content.
  """
  def create(server, entity, message) do
    {multi, events} = LogInternal.create(server, entity, message)

    multi
    |> Multi.run(:events, fn _ -> {:ok, events} end)
    |> Repo.transaction()
  end

  @spec revise(Log.t, Entity.id, String.t, pos_integer) ::
    {:ok, %{revision: any, log_touch: any, events: [Event.t]}}
    | {:error, :revision | :log_touch, Ecto.Changeset.t, map}
  @doc """
  Adds a revision over `log`.

  `entity` is the ID of the entity that is doing the revision, `message` is the
  new log's content and `forge_version` is the version of log forger used to
  make this revision.
  """
  def revise(log, entity, message, forge_version) do
    {multi, events} = LogInternal.revise(log, entity, message, forge_version)

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
    multi = LogInternal.recover(log)

    multi
    |> Multi.run(:events, fn %{log: {:event, events}} ->
      {:ok, events}
    end)
    |> Repo.transaction()
  end

  @spec hard_delete(Log.t) ::
    {:ok, Log.t}
    | {:error, reason :: term}
  @doc """
  Deletes the log by removing its entry from database
  """
  def hard_delete(log),
    do: Repo.delete(log)
end
