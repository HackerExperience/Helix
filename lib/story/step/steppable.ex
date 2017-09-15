defprotocol Helix.Story.Steppable do

  def filter_event(step)

  def complete(step)

  def next_step(step)
end
