defprotocol Helix.Process.Model.Process.ProcessType do

  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.State

  @type resource :: :cpu | :ram | :dlk | :ulk

  @spec dynamic_resources(t) :: [resource]
  def dynamic_resources(data)

  @spec conclusion(t, Process.t | Ecto.Changeset.t) ::
    {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def conclusion(data, process)

  @spec state_change(t, Process.t | Ecto.Changeset.t, State.state, State.state) ::
    {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def state_change(data, process, from, to)

  @spec kill(t, Process.t | Ecto.Changeset.t, atom) ::
    {[Process.t | Ecto.Changeset.t] | Process.t | Ecto.Changeset.t, [struct]}
  def kill(data, process, reason)

  @spec minimum(t) ::
    %{optional(State.state) => %{resource => non_neg_integer}}
  def minimum(data)
end

###########################################
# IGNORE THE FOLLOWING LINES.
# Dialyzer is not particularly a fan of protocols, so it will emit a lot of
# "unknown functions" for non-implemented types on a protocol. This hack will
# implement any possible type to avoid those warnings (albeit it might increase
# the compilation time in a second)
###########################################

impls = [
  Atom,
  BitString,
  Float,
  Function,
  Integer,
  List,
  Map,
  PID,
  Port,
  Reference,
  Tuple
]

for impl <- impls do
  defimpl Helix.Process.Model.Process.ProcessType, for: impl do
    def dynamic_resources(input),
      do: raise "#{inspect input} doesn't implement ProcessType protocol"
    def state_change(input, _, _, _),
      do: raise "#{inspect input} doesn't implement ProcessType protocol"
    def kill(input, _, _),
      do: raise "#{inspect input} doesn't implement ProcessType protocol"
    def minimum(input),
      do: raise "#{inspect input} doesn't implement ProcessType protocol"
    def conclusion(input, _),
      do: raise "#{inspect input} doesn't implement ProcessType protocol"
  end
end
