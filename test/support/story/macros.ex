defmodule Helix.Test.Story.Macros do

  alias HELL.Utils

  @doc """
  Asserts that the story has transitioned from the current one (identified by
  `name` on StepVars) to the next one (identified by `next` on StepVars).
  """
  defmacro assert_transition(event, step_var) do
    quote do

      event_from = unquote(event).data.previous_step
      event_to = unquote(event).data.next_step

      assert String.contains?(event_from, unquote(step_var).name)
      assert String.contains?(event_to, unquote(step_var).next)

    end
  end

  @doc """
  Asserts that the received email is the one expected, including the allowed
  replies and the contact/step are the same as before.
  """
  defmacro assert_email(event, expected_email, replies, step_var) do
    quote do

      event_data = unquote(event).data
      replies = Utils.ensure_list(unquote(replies))

      expected_email = Map.fetch!(unquote(step_var), unquote(expected_email))

      assert unquote(event).event == "story_email_sent"
      assert event_data.email_id == expected_email

      if Enum.empty?(replies) do
        assert Enum.empty?(event_data.replies)
      else
        Enum.each(replies, fn reply ->
          reply = Map.fetch!(unquote(step_var), reply)
          assert Enum.member?(event_data.replies, reply)
        end)
      end

      assert event_data.contact_id == to_string(unquote(step_var).contact)
      assert event_data.step =~ to_string(unquote(step_var).name)

    end
  end

  @doc """
  Asserts that the received reply is the one expected, including the allowed
  replies, which message it was replying to, and the contact/step are the same.

  NOTE: Not to confuse with `assert_reply/4` macro on `Phoenix.ChannelTest`.
  """
  defmacro assert_reply(event, expected_reply, reply_to, replies, step_var) do
    quote do

      event_data = unquote(event).data
      replies = Utils.ensure_list(unquote(replies))

      expected_reply = Map.fetch!(unquote(step_var), unquote(expected_reply))
      reply_to = Map.fetch!(unquote(step_var), unquote(reply_to))

      assert unquote(event).event == "story_reply_sent"
      assert event_data.reply_id == expected_reply
      assert event_data.reply_to == reply_to

      Enum.each(replies, fn reply ->
        reply = Map.fetch!(unquote(step_var), reply)
        assert Enum.member?(event_data.replies, reply)
      end)

      assert event_data.contact_id == to_string(unquote(step_var).contact)
      assert event_data.step =~ to_string(unquote(step_var).name)
    end
  end
end
