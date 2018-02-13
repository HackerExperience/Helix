defmodule Helix.Story.Event.Reply do

  import Helix.Event

  event Sent do
    @moduledoc """
    StoryReplySentEvent is fired when the Player has replied a Contact
    (Storyline character), sending her an email
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step
    alias Helix.Story.Model.Story

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        step: Step.t,
        reply_to: Step.email_id,
        reply: Story.Email.email,
      }

    event_struct [:entity_id, :step, :reply_to, :reply]

    @spec new(Step.t, reply :: Story.Email.email, Step.email_id) ::
      t
    def new(step = %_{name: _, entity_id: _}, reply = %{id: _}, reply_to) do
      %__MODULE__{
        entity_id: step.entity_id,
        step: step,
        reply_to: reply_to,
        reply: reply
      }
    end

    notify do
      @moduledoc false

      alias HELL.ClientUtils

      @event :story_reply_sent

      def generate_payload(event, _socket) do
        contact_id = Step.get_contact(event.step) |> to_string()
        replies =
          event.step
          |> Step.get_replies_of(event.reply.id)
          |> Enum.map(&to_string/1)

        data = %{
          step: to_string(event.step.name),
          contact_id: contact_id,
          reply_to: event.reply_to,
          reply_id: event.reply.id,
          replies: replies,
          timestamp: ClientUtils.to_timestamp(event.reply.timestamp),
        }

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
