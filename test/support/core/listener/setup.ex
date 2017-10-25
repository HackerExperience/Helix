defmodule Helix.Test.Core.Listener.Setup do

  alias Ecto.Changeset
  alias Helix.Core.Listener.Model.Listener
  alias Helix.Core.Listener.Internal.Listener, as: ListenerInternal

  alias Helix.Test.Core.Listener.Helper, as: ListenerHelper

  @doc """
  See doc on `fake_listener/1`
  """
  def listener(opts \\ []) do
    {_, related = %{params: params, event: event, callback: callback}} =
      fake_listener(opts)

    {:ok, inserted} =
      ListenerInternal.listen(
        params.object_id,
        event,
        callback,
        params.meta,
        params.owner_id,
        params.subscriber
      )

    {inserted, related}
  end

  @doc """
  Opts:
  - object_id: Which object is being listened to.
  - event: What events should the object respond to.
  - callback: What function should be called when/if that event occurs.
  - meta: Extra parameters to the callback. Defaults to nil.

  Returns:
    original_event :: String.t, \
    callback :: {atom, atom}, \
    changeset :: Listener.changeset,
    params :: Listener.creation_params
  """
  def fake_listener(opts \\ []) do

    object_id = Keyword.get(opts, :object_id, ListenerHelper.random_object_id())
    event = Keyword.get(opts, :event, ListenerHelper.random_event())
    callback = Keyword.get(opts, :callback, ListenerHelper.random_callback())
    meta = Keyword.get(opts, :meta, nil)
    owner_id = Keyword.get(opts, :owner_id, ListenerHelper.random_object_id())
    subscriber = Keyword.get(opts, :subscriber, ListenerHelper.random_event())

    {module, method} = callback

    params = %{
      object_id: object_id,
      event: Listener.hash_event(event),
      callback: [module, method],
      meta: meta,

      # Used by `listener/1` only
      owner_id: owner_id,
      subscriber: subscriber
    }

    changeset = Listener.create_changeset(params)

    listener = Changeset.apply_changes(changeset)

    related = %{
      event: event,
      callback: callback,
      changeset: changeset,
      params: params
    }

    {listener, related}
  end
end
