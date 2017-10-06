defprotocol Helix.Log.Loggable do
  @moduledoc """
  The Loggable protocol, alongside with the LoggableFlow, must be implemented by
  any event that would like to add a log entry to one or more servers.

  For the most part, the Loggable protocol itself is simply an implementation
  detail. For a better explanation on how to implement it, refer to the
  LoggableFLow documentation.
  """

  alias Helix.Event
  alias Helix.Log.Loggable.Flow, as: LoggableFlow

  @spec generate(Event.t) ::
    [LoggableFlow.log_entry]
  @doc """
  Function responsible for returning a list of log entries, which will later be
  used by LoggableFlow.save/1 to be stored on the database.
  """
  def generate(event)
end
