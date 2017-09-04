defmodule Helix.Log.Public.Index do

  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log
  alias Helix.Log.Query.Log, as: LogQuery

  @type index ::
    [%{log_id: Log.id, message: Log.message, inserted_at: DateTime.t}]

  @type rendered_index ::
    [%{log_id: String.t, message: String.t, inserted_at: String.t}]

  @spec index(Server.id) ::
    index
  @doc """
  Returns the Log index, with information about the logs on the server.

  Pagination is TODO (and probably will require a specific topic/request).
  Meta information is also TODO (like, whether a specific log was edited by the
  player, etc.)
  """
  def index(server_id) do
    server_id
    |> LogQuery.get_logs_on_server()
    |> Enum.map(fn log ->
      %{
        log_id: log.log_id,
        message: log.message,
        inserted_at: log.inserted_at
      }
    end)
  end

  @spec render_index(index) ::
    rendered_index
  @doc """
  Top-level renderer for `index/1`
  """
  def render_index(index) do
    Enum.map(index, fn log ->
      %{
        log_id: to_string(log.log_id),
        message: log.message,
        inserted_at: to_string(log.inserted_at)
      }
    end)
  end
end
