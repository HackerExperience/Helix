defmodule Helix.Test.Log.Helper do

  import Ecto.Query

  alias Helix.Event.Loggable.Utils, as: LoggableUtils
  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.Revision
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo, as: LogRepo

  alias Helix.Test.Log.Setup.LogType, as: LogTypeSetup

  @doc """
  Given a log, returns the expected format of a public view.
  """
  def public_view(log_list) when is_list(log_list),
    do: Enum.map(log_list, &(public_view(&1)))
  def public_view(log) do
    %{
      log_id: log.log_id,
      message: List.first(log.revisions).message,
      timestamp: log.creation_time
    }
  end

  def random_message do
    "This is a random log message"
  end

  def id,
    do: Log.ID.generate(%{}, :log)

  @doc """
  Returns a random `Log.info`.
  """
  def log_info(opts \\ []),
    do: LogTypeSetup.log_info(opts)

  def log_file_name(file),
    do: LoggableUtils.get_file_name(file)

  @doc """
  This method should be used when the tester wants to fetch the most recent log
  of type `log_type` that was created on `server_id`. One might wonder, then,
  why not use `LogQuery.get_logs_on_server/1`. Here it goes:

  Logs are ordered by ID. The MSB of a Log ID heritage corresponds to the server
  it resides. Then, we have 30 bits dedicated to the time the log was created,
  and finally 36 bits that are random, innate to the log itself (if this
  paragraph made no sense, then please read docs at `lib/id/id.ex`).

  Notice that, as a result, all logs created on the same server, at the same
  time hash (i.e. same second) have their order determined by the 36 random bits
  of the object, and as such their order is non-deterministic. 

  That's a problem for testing, as several logs will be created at the same
  second. In real life, however, this is unlikely to happen, and if it does -
  (multiple logs are created on the same server at the same second) - whichever
  order we get is fine.

  So, to sum it up, `get_last_log/2` retrieves the most recent `log_type` on
  `server_id`, making this query deterministic.
  """
  def get_last_log(server = %Server{}, log_type),
    do: get_last_log(server.server_id, log_type)
  def get_last_log(server_id = %Server.ID{}, log_type) do
    server_id
    |> LogQuery.get_logs_on_server()
    |> Enum.find(fn log -> log.revision.type == log_type end)
  end

  @doc """
  Returns all existing revisions for the given log.
  """
  def get_all_revisions(log = %Log{}),
    do: get_all_revisions(log.log_id)
  def get_all_revisions(log_id = %Log.ID{}) do
    query =
      from lr in Revision,
        where: lr.log_id == ^log_id,
        order_by: [desc: lr.revision_id]

    LogRepo.all(query)
  end

  @doc """
  Directly deletes a log on the DB. Use with caution!
  """
  def delete(log = %Log{}),
    do: LogRepo.delete(log)
end
