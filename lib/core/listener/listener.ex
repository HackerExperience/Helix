defmodule Helix.Core.Listener do
  @moduledoc """
  Main interface to be used by any service that would like to listen/unlisten to
  events happening to a specific `object_id`.

  I'm a Listener

    And then I saw her face
    Now I'm a listener
    Not a trace
    Of doubt in my mind
    I'm in love
    I'm a listener
    I couldn't leave her
    If I tried
  """

  import HELL.Macros

  alias Helix.Core.Listener.Action.Listener, as: ListenerAction

  @doc """
  Subscribes to `events` on `object_id`, calling `method` as a callback once/if
  the event happens.
  """
  defmacro listen(object_id, events, method, opts) do
    module = __CALLER__.module
    quote do
      do_listen(
        unquote(object_id),
        unquote(events),
        {unquote(module), unquote(method)},
        unquote(opts)
      )
    end
  end

  def do_listen(object_id, event, callback, opts) when not is_list(event),
    do: do_listen(object_id, [event], callback, opts)

  def do_listen(object_id, events, {module, method}, opts) do
    owner_id = opts[:owner_id] || raise "Please specify owner id"
    subscriber = Keyword.get(opts, :subscriber, nil)
    meta = Keyword.get(opts, :meta, nil)

    Enum.each(events, fn event ->
      assert_aliased(event)

      ListenerAction.listen(
        object_id, event, {module, method}, meta, owner_id, subscriber
      )
    end)
  end

  @doc """
  Unsubscribes to `event` happening over `object_id`. The `owner_id` and
  `subscriber` are used as identifiers to make sure the service is unsubscribing
  to some subscription made by itself (not by a foreign service, which may still
  be interested on the same `event` happening over the same `object_id`).
  """
  def unlisten(owner_id, object_id, event, subscriber),
    do: ListenerAction.unlisten(owner_id, object_id, event, subscriber)

  docp """
  `assert_aliased` makes sure that the given event has been aliased by whoever
  is trying to subscribe to events on it. The reason being that, if not aliased,
  the module will be able to listen on a bogus event and no warnings will be
  emitted.
  """
  defp assert_aliased(event) do
    module_depth =
      event
      |> Module.split()
      |> length()

    if module_depth == 1,
      do: raise "Event #{event} isn't aliased"
  end
end
