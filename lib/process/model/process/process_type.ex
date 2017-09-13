defprotocol Helix.Process.Model.Process.ProcessType do

  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.State

  @type resource :: :cpu | :ram | :dlk | :ulk

  @spec dynamic_resources(t) ::
    [resource]
  def dynamic_resources(data)

  @spec conclusion(t, Process.t | Ecto.Changeset.t) ::
    {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def conclusion(data, process)

  @spec state_change(t, Ecto.Changeset.t, State.state, State.state) ::
    {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def state_change(data, process, from, to)

  @spec kill(t, Process.t | Ecto.Changeset.t, atom) ::
    {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def kill(data, process, reason)

  @spec minimum(t) ::
    %{optional(State.state) => %{resource => non_neg_integer}}
  def minimum(data)

  @spec after_read_hook(term) ::
    t
  @doc """
  Process metadata (ProcessType) is stored as JSONB on Postgres. After
  retrieval, we may lose some internal data representation, like Helix IDs or
  atoms, which are both converted to string. This method purpose is somewhat
  similar to serialization.
  """
  def after_read_hook(data)
end
