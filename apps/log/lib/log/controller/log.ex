defmodule Helix.Log.Controller.Log do

  alias HELL.PK
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Revision
  alias Helix.Log.Repo


  @spec create(
    PK.t,
    PK.t,
    String.t) :: {:ok, Log.t} | {:error, reason :: term}
  @spec create(
    PK.t,
    PK.t,
    String.t,
    non_neg_integer) :: {:ok, Log.t} | {:error, reason :: term}
  def create(server_id, player_id, message, forge_version \\ nil) do
    params = %{
      server_id: server_id,
      player_id: player_id,
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

  def create!(server_id, player_id, message, forge_version \\ nil) do
    case create(server_id, player_id, message, forge_version) do
      {:ok, log} ->
        log
      _ ->
        raise RuntimeError
    end
  end

  @spec fetch(PK.t) :: Log.t | nil
  def fetch(log_id) do
    Repo.get_by(Log, log_id: log_id)
  end

  @spec revise(
    Log.t,
    PK.t,
    String.t,
    non_neg_integer) :: {:ok, Log.t} | {:error, reason :: term}
  def revise(log, player_id, message, forge_version) do
    params = %{
      log_id: log.log_id,
      player_id: player_id,
      message: message,
      forge_version: forge_version
    }

    revision = Revision.create_changeset(params)

    case Repo.insert(revision) do
      {:ok, _revision} ->
        {:ok, log}
      {:error, changeset} ->
        IO.inspect(changeset)
        # TODO: Traverse changeset to provide proper error message
        {:error, :internal_error}
    end
  end

  def revise!(log, player_id, message, forge_version) do
    case revise(log, player_id, message, forge_version) do
      {:ok, log} ->
        log
      _ ->
        raise RuntimeError
    end
  end

  @spec recover(Log.t) :: {:ok, :deleted | Log.t} | {:error, reason :: term}
  def recover(log) do
    case Repo.preload(log, :revisions) do
      %{revisions: [%{forge_version: nil}]} ->
        # Log is in it's original form
        {:error, :cannot_recover}
      log = %{revisions: [%{forge_version: _}]} ->
        # Log was forged and can be deleted

        case Repo.delete(log) do
          {:ok, _} ->
            {:ok, :deleted}
          e ->
            e
        end
      log = %{revisions: revisions} ->
        # Log still has revisions left and can be recovered to another version
        [h| t] = Enum.sort_by(revisions, &(&1.forge_version))

        Repo.delete(h)

        [%{message: msg} | _] = t
        %{log| revisions: t}
        |> Log.update_changeset(%{message: msg})
        |> Repo.update()
    end
  end

  @spec encrypt(
    Log.t,
    non_neg_integer) :: {:ok, Log.t} | {:error, Ecto.Changeset.t}
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
end