defprotocol Helix.Process.API.View.Process do

  # Entity and Server data are included to allow the viewable to render
  # differently for the process creator or if seen from an external server
  def render(data, process, server_id, entity_id)
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
  defimpl Helix.Process.API.View.Process, for: impl do
    def render(input, _, _, _),
      do: raise "#{inspect input} doesn't implement ProcessView protocol"
  end
end
