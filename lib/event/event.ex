defmodule Helix.Event do

  alias Helix.Event.Dispatcher, as: HelixDispatcher

  @type t :: HELF.Event.t

  @doc """
  Top-level macro for an event.

  It automatically imports common Flows.
  """
  defmacro event(name, do: block) do
    quote do

      defmodule unquote(name) do

        import Helix.Event.Loggable.Flow
        import Helix.Event.Notificable.Flow

        unquote(block)
      end

    end
  end

  @doc """
  Specifies the event struct with the given keys plus the meta ones.

  By default it enforces all keys to be set.
  """
  defmacro event_struct(keys) do
    meta_keys = [:__eid__]
    quote do

      @enforce_keys unquote(keys)
      defstruct unquote(keys) ++ unquote(meta_keys)

    end
  end

  docp """
  The application wants to emit `event`, which is coming from `source`. On this
  case, `event` will inherit the source's metadata according to the logic below.
  """
  defp inherit(event, source) do
    event
  end

  @spec emit([t] | t, from: t) ::
    term
  @doc """
  Emits an event, inheriting data from the source event passed on the `from`
  parameter. The inherited data is defined at `inherit/2`.
  """
  def emit([], from: _),
    do: :noop
  def emit(events = [_ | _], from: source_event),
    do: Enum.ech(events, &emit/2)
  def emit(event, from: source_event) do
    event
    |> inherit(source_event)
    |> emit()
  end

  @spec emit([t] | t) ::
    term
  @doc """
  Emits an event, or a list of events, through Helix Dispatcher.
  """
  def emit([]),
    do: :noop
  def emit(events = [_|_]),
    do: Enum.each(events, &emit/1)
  def emit(event),
    do: HelixDispatcher.emit(event)
end
