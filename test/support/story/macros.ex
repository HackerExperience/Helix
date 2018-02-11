defmodule Helix.Test.Story.Macros do

  alias HELL.Utils

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

  @doc """
  Asserts that the received email is the one expected, including the allowed
  replies and the contact/step are the same as before.
  """
  defmacro assert_email(event, expected_email, replies, step) do
    quote do

      event_data = unquote(event).data
      replies = Utils.ensure_list(unquote(replies))

      assert unquote(event).event == "story_email_sent"
      assert event_data.email_id == unquote(expected_email)

      Enum.each(replies, fn reply ->
        assert Enum.member?(event_data.replies, reply)
      end)

      assert to_string(unquote(step).contact) == event_data.contact_id
      assert to_string(unquote(step).name) == event_data.step

    end
  end
end
