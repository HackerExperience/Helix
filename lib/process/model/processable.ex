defprotocol Helix.Process.Model.Processable do

  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.State

  # @type resource :: :cpu | :ram | :dlk | :ulk

  @type action ::
    :delete
    | :pause
    | :resume
    | :renice
    | :restart

  # @spec complete(t, Process.t | Ecto.Changeset.t) ::
  #   {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def complete(data, process)

  # @spec kill(t, Process.t | Ecto.Changeset.t, atom) ::
  #   {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def kill(data, process, reason)

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
