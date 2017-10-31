defmodule Helix.Core.Listener.Action.Listener do

  alias Helix.Core.Listener.Internal.Listener, as: ListenerInternal
  alias Helix.Core.Listener.Model.Listener
  alias Helix.Core.Listener.Model.Owner

  @spec listen(
    Listener.object_id,
    Listener.event,
    Listener.callback_tuple,
    Listener.meta,
    Owner.id,
    Owner.subscriber
  ) ::
    {:ok, Listener.t}
    | {:error, Listener.changeset}
  def listen(object_id, event, {module, method}, meta, owner_id, subscriber) do
    object_id = to_string(object_id)
    event = to_string(event)
    {module, method} = {to_string(module), to_string(method)}
    owner_id = to_string(owner_id)
    subscriber = to_string(subscriber)

    ListenerInternal.listen(
      object_id, event, {module, method}, meta, owner_id, subscriber
    )
  end

  @spec unlisten(
    Owner.id, Listener.object_id, Listener.event, Owner.subscriber
  ) ::
    :ok
  def unlisten(owner_id, object_id, event, subscriber) do
    owner_id = to_string(owner_id)
    object_id = to_string(object_id)
    event = to_string(event)
    subscriber = to_string(subscriber)

    ListenerInternal.unlisten(owner_id, object_id, event, subscriber)
  end
end
