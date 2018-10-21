defmodule Helix.Log.Query.Log do
  @moduledoc """
  Functions to query in-game logs
  """

  alias Helix.Server.Model.Server
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

  @spec paginate_logs_on_server(Server.id, Log.id, pos_integer) ::
    [Log.t]
  defdelegate paginate_logs_on_server(server_id, last_log_id, count),
    to: LogInternal
end
