defprotocol Helix.Event.Listenable do
  @moduledoc """
  See doc on `Event.Listenable.Flow`.
  """

  alias Helix.Event

  @spec get_objects(Event.t) ::
    [object_id :: term]
  @doc """
  Returns a list of potentially useful IDs present on the event.
  """
  def get_objects(event)
end
