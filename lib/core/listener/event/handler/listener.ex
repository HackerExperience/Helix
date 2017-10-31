defmodule Helix.Core.Listener.Event.Handler.Listener do
  @moduledoc """
  Listens to all events, verifying whether any of them is of interest to other
  services, and executes the callback if so.
  """

  alias Helix.Event
  alias Helix.Event.Listenable
  alias Helix.Core.Listener.Model.Listener
  alias Helix.Core.Listener.Query.Listener, as: ListenerQuery

  @spec listener_handler(Event.t) ::
    term
  @doc """
  `listener_handler/1` is responsible for listening to all events and, in case
  it implements the `Listenable` protocol, it will check if there are any
  services subscribed to that specific event under that specific object ID.
  """
  def listener_handler(event) do
    if Listenable.impl_for(event) do
      event
      |> Listenable.get_objects()
      |> Enum.each(fn object_id -> find_listeners(object_id, event) end)
    end
  end

  @spec find_listeners(term | Listener.object_id, Event.t) ::
    term
  defp find_listeners(object_id, event) do
    object_id
    |> ListenerQuery.get_listeners(event.__struct__)
    |> Enum.each(fn listener -> execute_callback(listener, event) end)
  end

  @spec execute_callback(Listener.info, Event.t) ::
    term
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
