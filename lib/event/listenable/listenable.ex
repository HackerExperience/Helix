defprotocol Helix.Event.Listenable do

  alias Helix.Event

  @spec get_objects(Event.t) ::
    [object_id :: term]
  def get_objects(event)
end
