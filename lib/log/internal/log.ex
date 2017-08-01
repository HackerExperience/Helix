defmodule Helix.Log.Internal.Log do
  @moduledoc false

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.LogTouch
  alias Helix.Log.Model.Revision
  alias Helix.Log.Repo

  @spec fetch(Log.id) ::
    Log.t
    | nil
  def fetch(log_id),
    do: Repo.get(Log, log_id)

  @spec get_logs_on_server(Server.t | Server.id) ::
    [Log.t]
  def get_logs_on_server(server) do
    server
    |> Log.Query.by_server()
    # TODO: Use id's timestamp
    |> Log.Query.order_by_newest()
    |> Repo.all()
  end

  @spec get_logs_from_entity_on_server(Server.t | Server.id, Entity.t | Entity.id) ::
    [Log.t]
  def get_logs_from_entity_on_server(server, entity) do
    server
    |> Log.Query.by_server()
    # TODO: Use id's timestamp
    |> Log.Query.order_by_newest()
    |> Log.Query.edited_by_entity(entity)
    |> Repo.all()
  end

  @spec create(Server.id, Entity.id, String.t, pos_integer | nil) ::
    {:ok, Log.t}
    | {:error, Ecto.Changeset.t}
  def create(server, entity, message, forge_version \\ nil) do
    params = %{
      server_id: server,
      entity_id: entity,
      message: message,
      forge_version: forge_version
    }

    changeset = Log.create_changeset(params)

    Repo.transaction fn ->
      with \
        {:ok, log} <- Repo.insert(changeset),
        {:ok, _} <- touch_log(log, entity)
      do
        log
      else
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end
  end

  @spec revise(log, Entity.t | Entity.id, String.t, pos_integer) ::
    {:ok, log}
    | {:error, Ecto.Changeset.t} when log: Log.t
  def revise(log, entity, message, forge_version) do
    revision = Revision.create(log, entity, message, forge_version)

    Repo.transaction fn ->
      with \
        {:ok, _} <- Repo.insert(revision),
        {:ok, _} <- touch_log(log, entity)
      do
        log
      else
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end
  end

  @spec recover(Log.t) ::
    {:ok, :deleted | :recovered}
    | {:error, :original_revision}
  def recover(log) do
    Repo.transaction fn ->
      query =
        log
        |> Revision.Query.by_log()
        |> Revision.Query.last(2)

      case Repo.all(query) do
        [%{forge_version: nil}] ->
          Repo.rollback(:original_revision)

        [_] ->
          # Forged log, should be deleted
          Repo.delete!(log)

          :deleted

        [old, %{message: m}] ->
          Repo.delete!(old)

          log
          |> Log.update_changeset(%{message: m})
          |> Repo.update!()

          :recovered
      end
    end
  end

  @spec touch_log(Log.t, Entity.t | Entity.id) ::
    {:ok, LogTouch.t}
    | {:error, Ecto.Changeset.t}
  defp touch_log(log, entity) do
    log
    |> LogTouch.create(entity)
    |> Repo.insert(on_conflict: :nothing)
  end
end
