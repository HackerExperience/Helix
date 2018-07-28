defmodule Helix.Log.Public.Index do

  alias HELL.ClientUtils
  alias HELL.HETypes
  alias HELL.Utils
  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log
  alias Helix.Log.Query.Log, as: LogQuery

  @type index :: [Log.t]

  @type rendered_index :: [rendered_log]

  @typep rendered_log ::
    %{
      log_id: String.t,
      type: String.t,
      data: map,
      timestamp: HETypes.client_timestamp
    }

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
  end

  @spec render_index(index) ::
    rendered_index
  @doc """
  Top-level renderer for `index/1`
  """
  def render_index(index),
    do: Enum.map(index, &render_log/1)

  @spec render_log(Log.t) ::
    rendered_log
  def render_log(log = %Log{}) do
    %{
      log_id: to_string(log.log_id),
      type: to_string(log.revision.type),
      data: Utils.stringify_map(log.revision.data),
      timestamp: ClientUtils.to_timestamp(log.creation_time)
    }
  end
end
