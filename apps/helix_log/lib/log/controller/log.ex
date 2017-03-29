defmodule Helix.Log.Controller.Log do

  alias HELL.PK
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Revision
  alias Helix.Log.Repo

  @type find_param ::
    {:server_id, PK.t}
    | {:message, String.t}

  @spec create(
    PK.t,
    PK.t,
    String.t) :: {:ok, Log.t} | {:error, reason :: term}
  @spec create(
    PK.t,
    PK.t,
    String.t,
    non_neg_integer | nil) :: {:ok, Log.t} | {:error, reason :: term}
  def create(server_id, entity_id, message, forge_version \\ nil) do
    params = %{
      server_id: server_id,
      entity_id: entity_id,
      message: message,
      forge_version: forge_version
    }

    log = Log.create_changeset(params)

    case Repo.insert(log) do
      {:ok, log} ->
        {:ok, log}
      {:error, _changeset} ->
        # TODO: Traverse changeset to provide proper error message
        {:error, :internal_error}
    end
  end

  def create!(server_id, entity_id, message, forge_version \\ nil) do
    case create(server_id, entity_id, message, forge_version) do
      {:ok, log} ->
        log
      _ ->
        raise RuntimeError
    end
  end

  @spec fetch(PK.t) :: Log.t | nil
  def fetch(log_id),
    do: Repo.get(Log, log_id)

  @spec find([find_param], meta :: []) :: [Log.t]
  def find(params, _meta \\ []) do
    params
    |> Enum.reduce(Log, &reduce_find_params/2)
    |> Repo.all()
  end

  @spec revise(
    Log.t,
    PK.t,
    String.t,
    non_neg_integer) :: {:ok, Log.t} | {:error, reason :: term}
  def revise(log, entity_id, message, forge_version) do
    params = %{
      log_id: log.log_id,
      entity_id: entity_id,
      message: message,
      forge_version: forge_version
    }

    revision = Revision.create_changeset(params)

    case Repo.insert(revision) do
      {:ok, _revision} ->
        {:ok, log}
      {:error, _changeset} ->
        # TODO: Traverse changeset to provide proper error message
        {:error, :internal_error}
    end
  end

  def revise!(log, entity_id, message, forge_version) do
    case revise(log, entity_id, message, forge_version) do
      {:ok, log} ->
        log
      _ ->
        raise RuntimeError
    end
  end

  @spec recover(
    Log.t,
    PK.t) :: {:ok, :deleted | Log.t} | {:error, reason :: term}
  def recover(log, revision_id) do
    # TODO: Ensure revision order
    revisions =
      log
      |> Repo.preload(:revisions)
      |> Map.fetch!(:revisions)

    case Enum.split_with(revisions, &(&1.revision_id == revision_id)) do
      # YEP, i know that this is not the ideal order for a pattern but othewise
      # i would have to match the forge_version and guard agains nil value
      # everywhere
      {[%{forge_version: nil}], _} ->
        {:error, :raw}
      {[x], xs = [%{message: msg}]} ->
        Repo.delete(x)

        %{log| revisions: xs}
        |> Log.update_changeset(%{message: msg})
        |> Repo.update()
      {[_], []} ->
        case Repo.delete(log) do
          {:ok, _} ->
            {:ok, :deleted}
          e ->
            e
        end
      {[], _} ->
        {:ok, log}
    end
  end

  @spec encrypt(
    Log.t,
    non_neg_integer | nil) :: {:ok, Log.t} | {:error, Ecto.Changeset.t}
  def encrypt(log, crypto_version) do
    log
    |> Log.update_changeset(%{crypto_version: crypto_version})
    |> Repo.update()
  end

  @spec decrypt(Log.t) :: {:ok, Log.t} | {:error, Ecto.Changeset.t}
  def decrypt(log) do
    # Yep, a decrypted log is a log encrypted without a crypto (WHAT?)
    encrypt(log, nil)
  end

  @spec reduce_find_params(find_param, Ecto.Queryable.t) :: Ecto.Queryable.t
  defp reduce_find_params({:server_id, server_id}, query),
    do: Log.Query.by_server(query, server_id)
  defp reduce_find_params({:message, message}, query),
    do: Log.Query.by_message(query, message)
end
