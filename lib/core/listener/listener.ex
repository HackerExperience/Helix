defmodule Helix.Core.Listener do

  alias Helix.Core.Listener.Action.Listener, as: ListenerAction

  defmacro listen(object_id, event, method, opts) do
    module = __CALLER__.module
    quote do
      do_listen(
        unquote(object_id),
        unquote(event),
        {unquote(module), unquote(method)},
        unquote(opts)
      )
    end
  end

  def do_listen(object_id, event, callback, opts) when not is_list(event),
    do: do_listen(object_id, [event], callback, opts)

  def do_listen(object_id, events, {module, method}, opts) do
    owner_id = opts[:owner_id] || raise "abc"
    subscriber = Keyword.get(opts, :subscriber, nil)
    meta = Keyword.get(opts, :meta, nil)

    Enum.each(events, fn event ->
      ListenerAction.listen(
        object_id, event, {module, method}, meta, owner_id, subscriber
      )
    end)
  end

  def unlisten(owner_id, object_id, event, subscriber),
    do: ListenerAction.unlisten(owner_id, object_id, event, subscriber)
end
