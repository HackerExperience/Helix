defmodule Helix.Log.Query.Log do
  @moduledoc """
  Functions to query in-game logs
  """

  alias Helix.Server.Model.Server
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Internal.Log, as: LogInternal
  alias Helix.Log.Model.Log

  @doc """
  Fetches a log
  """
  defdelegate fetch(id),
    to: LogInternal

  defdelegate fetch_revisions(log),
    to: LogInternal

  @spec get_logs_on_server(Server.idt) ::
    [Log.t]
  @doc """
  Fetches logs on `server`
  """
  defdelegate get_logs_on_server(server),
    to: LogInternal

  @spec get_logs_from_entity_on_server(Server.idt, Entity.idt) ::
    [Log.t]
  @doc """
  Fetches logs on `server` that `entity` has created or revised
  """
  defdelegate get_logs_from_entity_on_server(server, entity),
    to: LogInternal

  @spec count_revisions_of_entity(Log.t, Entity.idt) ::
    non_neg_integer
  @doc """
  Returns the number of revisions on `log` that were created by `entity`

  ### Examples

      iex> count_revisions_of_entity(%Log{}, %Entity{})
      0

      iex> count_revisions_of_entity(%Log{}, %Entity.ID{})
      2

  Note that creating the log (either by forging it or by doing an action whose
  side-effect is to create a log) will create a revision for the log
  """
  defdelegate count_revisions_of_entity(log, entity),
    to: LogInternal
end
