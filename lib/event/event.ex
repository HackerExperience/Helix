defmodule Helix.Event do
  @moduledoc """
  `Helix.Event` serves two purposes:

  1. Define and declare an event, as well as how it's supposed to behave.
  2. Dispatch an event to `Helix.Event.Dispatcher` through `emit/1` or `emit/2`.
  """

  import HELL.Macros

  use Helix.Logger

  alias Helix.Websocket.Request.Relay, as: RequestRelay
  alias Helix.Process.Model.Process
  alias Helix.Event.Dispatcher, as: HelixDispatcher
  alias Helix.Event.Meta, as: EventMeta
  alias Helix.Event.State.Timer, as: EventTimer

  @type t :: HELF.Event.t
  @type source :: t | RequestRelay.t
  @type relay :: source | nil

  @doc """
  Top-level macro for an event.

  It automatically imports common Flows.
  """
  defmacro event(name, do: block) do
    quote do

      defmodule unquote(name) do

        import Helix.Event.Listenable.Flow
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
    meta_keys = [EventMeta.meta_key()]
    quote do

      @enforce_keys unquote(keys)
      defstruct unquote(keys) ++ unquote(meta_keys)

    end
  end

  # Delegates the `get_{field}` and `set_{field}` to Helix.Meta
  for field <- EventMeta.meta_fields() do
    defdelegate unquote(:"get_#{field}")(event),
      to: EventMeta
    defdelegate unquote(:"set_#{field}")(event, arg),
      to: EventMeta
  end

  @doc """
  This is pure syntactic sugar for: set_{field}(event, get_{field}(source))

  I.e. we get {field} from `source` and assign it to `event`.
  """
  defmacro relay(event, field, source) do
    quote do
      event = unquote(event)
      source = unquote(source)

      unquote(:"set_#{field}")(event, unquote(:"get_#{field}")(source))
    end
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
    do: Enum.each(events, &emit(&1, from: source_event))
  def emit(event, from: source_event) do
    event
    |> inherit(source_event)
    |> emit()

    log_event(event)
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
  def emit(event) do
    HelixDispatcher.emit(event)

    log_event(event)
  end

  @spec emit_after([t] | t, interval :: float | non_neg_integer) ::
    term
  @doc """
  Emits the given event(s) after `interval` milliseconds have passed.
  """
  def emit_after([], _),
    do: :noop
  def emit_after(events = [_|_], interval),
    do: Enum.each(events, &(emit_after(&1, interval)))
  def emit_after(event, interval),
    do: EventTimer.emit_after(event, interval)

  @spec inherit(t, source) ::
    t
  docp """
  The application wants to emit `event`, which is coming from `source`. On this
  case, `event` will inherit the source's metadata according to the logic below.

  Note that `source` may either be another event (`t`) or a request relay
  (`RequestRelay.t`). If it's a RequestRelay, then this event is being emitted
  as a result of a direct action from the player. On the other hand, if `source`
  is an event, it means this event is a side-effect of another event.
  """
  defp inherit(event, nil),
    do: event
  defp inherit(event, relay = %RequestRelay{}),
    do: set_request_id(event, relay.request_id)
  defp inherit(event, source) do
    # Relay the `process_id`
    event =
      case get_process_id(source) do
        process_id = %Process.ID{} ->
          set_process_id(event, process_id)
        nil ->
          event
      end

    # Accumulate source event on the stacktrace, and save it on the next event
    stack = get_stack(source) || []
    event = set_stack(event, stack ++ [source.__struct__])

    # Relay the request_id information
    event = relay(event, :request_id, source)

    # Everything has been inherited, we are ready to emit/1 the event.
    event
  end

  @spec log_event(t) ::
    term
  docp """
  Registers the information that an event has been sent.
  """
  defp log_event(event) do
    log :event, event.__struct__,
      data: %{
        event: event.__struct__,
        request_id: get_request_id(event)
      }
  end
end
