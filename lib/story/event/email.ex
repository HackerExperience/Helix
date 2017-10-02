defmodule Helix.Story.Event.Email do

  defmodule Sent do
    @moduledoc """
    StoryEmailSentEvent is fired when a Contact (Storyline character) sends an
    email to the Player.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        step: Step.step_name,
        email_id: Step.email_id,
        meta: Step.email_meta,
        timestamp: DateTime.t
      }

    @enforce_keys [:entity_id, :step, :email_id, :meta, :timestamp]
    defstruct [:entity_id, :step, :email_id, :meta, :timestamp]

    defimpl Helix.Event.Notificable do
      @moduledoc """
      Logic of the notification that will be sent to the client once the event
      `StoryEmailSent` is fired.
      """

      alias HELL.ClientUtils

      @event "story_email_sent"

      def generate_payload(event, _socket) do
        data = %{
          step: to_string(event.step),
          email_id: event.email_id,
          meta: event.meta,
          timestamp: ClientUtils.to_timestamp(event.timestamp)
        }

        {:ok, %{data: data, event: @event}}
      end

      @doc """
      Notify the player on his own channel.
      """
      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
