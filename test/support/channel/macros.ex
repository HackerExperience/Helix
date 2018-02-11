defmodule Helix.Test.Channel.Macros do

  @doc """
  The `wait_events` helper will wait for the requested events in a deterministic
  way, i.e. it doesn't matter the order they arrived.
  """
  defmacro wait_events(events, timeout \\ quote(do: 50)) do
    events = Enum.map(events, &to_string/1)
    quote do
      all_events = unquote(wait_all(timeout))

      Enum.reduce(unquote(events), [], fn event, acc ->
        case Enum.find(all_events, &(&1.event == event)) do
          e = %{} ->
            acc ++ [e]

          nil ->
            flunk("I did not receive the event \"#{event}\".")
        end
      end)

    end
  end

  def wait_all(timeout \\ 50) do
    quote do
      Enum.reduce_while(1..10, [], fn _, acc ->
        receive do
          %Phoenix.Socket.Message{event: "event", payload: event} ->
            {:cont, acc ++ [event]}

          after
            unquote(timeout) -> {:halt, acc}
        end
      end)
    end
  end

  @doc """
  Use `did_not_emit` to ensure a specific event was not pushed to the client.
  """
  defmacro did_not_emit(events, timeout \\ quote(do: 50)) do
    events = Enum.map(events, &to_string/1)

    quote do
      all_events = unquote(wait_all(timeout))

      Enum.each(unquote(events), fn event ->
        if Enum.find(all_events, &(&1.event == event)) do
          flunk("I received the event \"#{event}\", but you did not want to!")
        end
      end)
    end
  end

  @doc """
  Debugger/helper that lists all events in the mailbox.
  """
  defmacro list_events(timeout \\ quote(do: 50)) do
    quote do
      unquote(wait_all(timeout))
    end
  end
end
