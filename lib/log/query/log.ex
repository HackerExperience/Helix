defmodule Helix.Log.Query.Log do
  @moduledoc """
  Functions to query in-game logs
  """

  alias Helix.Server.Model.Server
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Model.Log

  @spec fetch(Log.id) ::
    Log.t
    | nil
  @doc """
  Fetches a log
  """
  defdelegate fetch(id),
    to: LogInternal

  @spec get_logs_on_server(Server.id, Keyword.t) ::
    [Log.t]
  @doc """
  Fetches logs on `server`
  """
  defdelegate get_logs_on_server(server, params \\ []),
    to: LogInternal

  @spec get_logs_from_entity_on_server(Server.id, Entity.id, Keyword.t) ::
    [Log.t]
  @doc """
  Fetches logs on `server` that `entity` has created or revised
  """
  defdelegate get_logs_from_entity_on_server(server, entity, params \\ []),
    to: LogInternal
end
