defmodule Helix.Test.Story.Macros do

  @doc """
  Asserts that the story has transitioned from `expected_from` to `expected_to`
  """
  defmacro assert_transition(event, expected_from, expected_to) do
    quote do
      event_from = unquote(event).data.previous_step
      event_to = unquote(event).data.next_step

      assert String.contains?(event_from, unquote(expected_from))
      assert String.contains?(event_to, unquote(expected_to))
    end
  end
end
