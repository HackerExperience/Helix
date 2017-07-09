defmodule Helix.Log.Query.Log do
  @moduledoc """
  Functions to query in-game logs
  """

  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Model.Log
  alias Helix.Log.Repo

  @type server_id :: LogInternal.server_id
  @type entity_id :: LogInternal.entity_id

  # FIXME: Repo actions should be on Internal.

  @spec fetch(Log.id) ::
    Log.t
    | nil
  @doc """
  Fetches a log
  """
  def fetch(id),
    do: Repo.one(LogInternal.fetch(id))

  @spec get_logs_on_server(server_id, Keyword.t) ::
    [Log.t]
  @doc """
  Fetches logs on `server`
  """
  def get_logs_on_server(server, params \\ []) do
    server
    |> LogInternal.get_logs_on_server(params)
    |> Repo.all()
  end

  @spec get_logs_from_entity_on_server(server_id, entity_id, Keyword.t) ::
    [Log.t]
  @doc """
  Fetches logs on `server` that `entity` has created or revised
  """
  def get_logs_from_entity_on_server(server, entity, params \\ []) do
    server
    |> LogInternal.get_logs_from_entity_on_server(entity, params)
    |> Repo.all()
  end
end
