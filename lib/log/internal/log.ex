defmodule Helix.Log.Internal.Log do
  @moduledoc false

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Revision
  alias Helix.Log.Repo

  @spec fetch(Log.id) ::
    Log.t
    | nil
  def fetch(log_id) do
    log_id
    |> Log.Query.by_id()
    |> Log.Query.include_revision()
    |> Repo.one()
  end

  @spec fetch_for_update(Log.id) ::
    Log.t
    | nil
  def fetch_for_update(log_id) do
    unless Repo.in_transaction?(),
      do: "Transaction required in order to acquire lock"

    log_id
    |> Log.Query.by_id()
    |> Log.Query.include_revision()
    |> Log.Query.lock_for_update()
    |> Repo.one()
  end

  @spec fetch_revision(Log.t, integer) ::
    Revision.t
    | nil
  def fetch_revision(log = %Log{}, offset) do
    log.log_id
    |> Revision.Query.by_log()
    |> Revision.Query.by_revision(log.revision_id + offset)
    |> Repo.one()
  end

  @spec fetch_revisions(Log.t) ::
    [Revision.t]
  def fetch_revisions(log = %Log{}) do
    log.log_id
    |> Revision.Query.by_log()
    |> Repo.all()
  end

  @spec get_logs_on_server(Server.id, pos_integer) ::
    [Log.t]
  def get_logs_on_server(server_id, count \\ 20) do
    server_id
    |> Log.Query.by_server()
    |> Log.Query.include_revision()
    |> Log.Query.only(count)
    |> Log.Order.by_id()
    |> Repo.all()
  end

  @spec paginate_logs_on_server(Server.id, Log.id, pos_integer) ::
    [Log.t]
  def paginate_logs_on_server(server_id, last_log_id, count \\ 20) do
    server_id
    |> Log.Query.by_server()
    |> Log.Query.paginate_after_log(last_log_id)
    |> Log.Query.include_revision()
    |> Log.Query.only(count)
    |> Log.Order.by_id()
    |> Repo.all()
  end

  @spec create(Server.id, Entity.id, Log.info, pos_integer | nil) ::
    {:ok, Log.t}
    | {:error, Log.changeset}
  @doc """
  Creates a new Log entry (along with its underlying Revision).

  The newly created Log may be natural (i.e. as a reaction to a game event) or
  artificial (i.e. crafted by the player). The `forge_version` defines whether
  it is natural (nil) or artificial (non-nil).
  """
  def create(server_id, entity_id, log_info, forge_version \\ nil) do
    {log_type, log_data} = log_info

    log_params = %{server_id: server_id}
    revision_params =
      %{
        entity_id: entity_id,
        forge_version: forge_version,
        type: log_type,
        data: Map.from_struct(log_data)
      }

    log_params
    |> Log.create_changeset(revision_params)
    |> Repo.insert()
  end

  @spec revise(Log.t, Entity.id, Log.info, pos_integer) ::
    {:ok, Log.t}
    | {:error, Log.changeset}
  @doc """
  Stacks up a new revision for the given `log`. It inserts a new Revision row
  and updates the existing Log row to point to the new `revision_id`.
  """
  def revise(log = %Log{}, entity_id, {log_type, log_data}, forge_version) do
    Repo.transaction fn ->
      log = fetch_for_update(log.log_id)

      params =
        %{
          entity_id: entity_id,
          forge_version: forge_version,
          type: log_type,
          data: Map.from_struct(log_data)
        }

      {log_changeset, revision_changeset} = Log.add_revision(log, params)

      with \
        {:ok, log} <- Repo.update(log_changeset),
        {:ok, _} <- Repo.insert(revision_changeset)
      do
        log
      else
        _ ->
          Repo.rollback(:internal)
      end
    end
  end

  @spec recover(Log.t) ::
    :destroyed
    | {:original, Log.t}
    | {:recovered, Log.t}
  @doc """
  Attempts to recover the given `log` to the previous version.

  If the log is already at the original server, it will either `:destroy` it if
  it's an artificial log, or return it as is if it's a natural one.

  Otherwise, if there exists a previous revision, it will pop the current one
  and point to the previous one, effectively deleting the current revision.
  """
  def recover(log = %Log{}) do
    trans_result =
      Repo.transaction fn ->
        log = fetch_for_update(log.log_id)
        previous_revision = fetch_revision(log, -1)

        case Log.recover_revision(log, previous_revision) do
          # We are attempting to recover a natural log. It should never be
          # destroyed, so we just return it as is.
          {:original, :natural} ->
            {:original, log}

          # We are dealing with an artificial log that is already on its last
          # revision. According to the game mechanics, this log should be
          # destroyed
          {:original, :artificial} ->
            Repo.delete!(log)
            :destroyed

          # It may either be a natural or artificial log, but we don't care, as
          # for both cases we need to recover to the `previous_revision`.
          {:recover, changeset} ->
            with {:ok, recovered_log} <- Repo.update(changeset) do
              {:recovered, recovered_log}
            end
        end
      end

    with {:ok, result} <- trans_result do
      result
    end
  end
end
