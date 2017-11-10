defmodule Helix.Test.Channel.Macros do

  defmacro wait_events(events) do
    events = Enum.map(events, &to_string/1)
    quote do
      all_events = unquote(wait_all())

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

  def wait_all do
    quote do
      Enum.reduce_while(1..10, [], fn _, acc ->
        receive do
          %Phoenix.Socket.Message{event: "event", payload: event} ->
            {:cont, acc ++ [event]}

          after
            50 -> {:halt, acc}
        end
      end)
    end
  end
end
