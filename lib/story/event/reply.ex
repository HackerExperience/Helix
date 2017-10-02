defmodule Helix.Story.Event.Reply do

  defmodule Sent do
    @moduledoc """
    StoryReplySentEvent is fired when the Player has replied a Contact
    (Storyline character), sending her an email
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        step: Step.step_name,
        reply_to: Step.email_id,
        reply_id: Step.reply_id,
        timestamp: DateTime.t
      }

    @enforce_keys [:entity_id, :step, :reply_to, :reply_id, :timestamp]
    defstruct [:entity_id, :step, :reply_to, :reply_id, :timestamp]

    defimpl Helix.Event.Notificable do
      @moduledoc false

      alias HELL.ClientUtils

      @event "story_reply_sent"

      def generate_payload(event, _socket) do
        data = %{
          step: to_string(event.step),
          reply_to: event.reply_to,
          reply_id: event.reply_id,
          timestamp: ClientUtils.to_timestamp(event.timestamp)
        }

        {:ok, %{data: data, event: @event}}
      end

      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
