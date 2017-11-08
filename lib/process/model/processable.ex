defprotocol Helix.Process.Model.Processable do

  # @type resource :: :cpu | :ram | :dlk | :ulk

  alias Helix.Event
  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process

  @type action ::
    :delete
    | :pause
    | :resume
    | :renice
    | :restart

  @spec complete(t, Process.t) ::
    {action, [Event.t]}
  def complete(data, process)

  @spec kill(t, Process.t, Process.kill_reason) ::
    {action, [Event.t]}
  def kill(data, process, reason)

  @spec connection_closed(t, Process.t, Connection.t) ::
    {action, [Event.t]}
  def connection_closed(data, process, connection)

  @spec after_read_hook(term) ::
    t
  @doc """
  Process metadata (Processable) is stored as JSONB on Postgres. After
  retrieval, we may lose some internal data representation, like Helix IDs or
  atoms, which are both converted to string. This method purpose is somewhat
  similar to serialization.
  """
  def after_read_hook(data)
end
