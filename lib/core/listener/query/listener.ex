defmodule Helix.Core.Listener.Query.Listener do

  alias Helix.Core.Listener.Internal.Listener, as: ListenerInternal
  alias Helix.Core.Listener.Model.Listener

  @spec get_listeners(term | Listener.object_id, term | Listener.event) ::
    [Listener.info]
  def get_listeners(object_id, event) when not is_binary(object_id),
    do: get_listeners(to_string(object_id), event)
  def get_listeners(object_id, event) when not is_binary(event),
    do: get_listeners(object_id, to_string(event))
  def get_listeners(object_id, event),
    do: ListenerInternal.get_listeners(object_id, event)
end
