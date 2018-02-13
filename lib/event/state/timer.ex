defmodule Helix.Event.State.Timer do
  @moduledoc """
  `EventTimer` is responsible for handling events that were asked to be emitted
  sometime in the future.
  """

  use GenServer

  alias Helix.Event

  @registry_name :event_timer

  # Client API

  def start_link,
    do: GenServer.start_link(__MODULE__, [], name: @registry_name)

  @spec emit_after(Event.t, interval :: float | non_neg_integer) ::
    term
  @doc """
  Emits `event` after `interval` milliseconds have passed.

  Unit is in milliseconds!
  """
  def emit_after(event, interval),
    do: GenServer.call(@registry_name, {:emit_after, event, interval})

  @doc """
  `flush` is a request to execute all events awaiting for its timer. Useful for
  testing and system restarts.
  """
  def flush,
    do: GenServer.call(@registry_name, :flush)

  # Callbacks

  def init(_),
    do: {:ok, []}

  def handle_call(:flush, _from, state) do
    Enum.each(state, fn {ref, event} ->
      spawn fn ->
        Event.emit(event)
        Process.cancel_timer(ref)
      end
    end)

    {:reply, :ok, []}
  end

  def handle_call({:emit_after, event, interval}, _from, state) do
    ref = Process.send_after(@registry_name, {:emit, event}, interval)

    {:reply, :ok, [{ref, event} | state]}
  end

  def handle_info({:emit, event}, state) do
    Event.emit(event)

    {:noreply, Enum.reject(state, fn {_, e} -> e == event end)}
  end
end
