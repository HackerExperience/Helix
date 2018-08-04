defmodule Helix.Log.Action.Log do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Model.Log

  alias Helix.Log.Event.Log.Created, as: LogCreatedEvent
  alias Helix.Log.Event.Log.Deleted, as: LogDeletedEvent
  alias Helix.Log.Event.Log.Revised, as: LogRevisedEvent

  @spec create(Server.id, Entity.id, Log.info, pos_integer | nil) ::
    {:ok, Log.t, [LogCreatedEvent.t]}
    | :error
  @doc """
  Creates a new log linked to `entity` on `server` with `log_info` as content.

  This log may be natural (created automatically by the game as a result to a
  player's action) or artificial (explicitly created using LogForger.Edit).
  """
  def create(server_id, entity_id, log_info, forge_version \\ nil) do
    case LogInternal.create(server_id, entity_id, log_info, forge_version) do
      {:ok, log} ->
        {:ok, log, [LogCreatedEvent.new(log)]}

      {:error, _} ->
        :error
    end
  end

  @spec revise(Log.t, Entity.id, Log.info, pos_integer) ::
    {:ok, Log.t, [LogRevisedEvent.t]}
    | :error
  @doc """
  Adds a revision to the given `log`.
  """
  def revise(log = %Log{}, entity_id, log_info, forge_version) do
    case LogInternal.revise(log, entity_id, log_info, forge_version) do
      {:ok, log} ->
        event = LogRevisedEvent.new(log)
        {:ok, log, [event]}

      {:error, _} ->
        :error
    end
  end

  @spec recover(Log.t) ::
    {:ok, :destroyed, [LogDeletedEvent.t]}
    | {:ok, :original, []}
    | {:ok, :recovered, [LogRecoveredEvent.t]}
  @doc """
  Attempts to recover the given `log`.
  """
  def recover(log = %Log{}) do
    case LogInternal.recover(log) do
      :destroyed ->
        {:ok, :destroyed, [LogDeletedEvent.new(log)]}

      {:original, _} ->
        {:ok, :original, []}

      {:recovered, new_log} ->
        {:ok, :recovered, [LogRecoveredEvent.new(new_log)]}
    end
  end
end
