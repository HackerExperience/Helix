defmodule Helix.Core.Listener.Event.Handler.Listener do

  alias Helix.Event
  alias Helix.Event.Listenable
  alias Helix.Software.Event.File.Downloaded, as: FileDownloadedEvent
  alias Helix.Core.Listener.Query.Listener, as: ListenerQuery

  def listener_handler(event) do
    if Listenable.impl_for(event) do
      event
      |> Listenable.get_objects()
      |> Enum.each(fn object_id -> find_listeners(object_id, event) end)
    end
  end

  defp find_listeners(object_id, event) do
    object_id
    |> ListenerQuery.get_listeners(event.__struct__)
    |> Enum.each(fn listener -> execute_callback(listener, event) end)
  end

  defp execute_callback(%{module: module, method: method, meta: meta}, event) do
    module = String.to_atom(module)
    method = String.to_atom(method)

    params =
      if meta do
        [event, meta]
      else
        [event]
      end

    {:ok, events} = apply(module, method, params)

    Event.emit(events)
  end
end
