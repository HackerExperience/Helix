defmodule Helix.Story.Event.Email do

  import Helix.Event

  event Sent do
    @moduledoc """
    `StoryEmailSentEvent` is fired when a Contact (Storyline character) sends an
    email to the Player.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step
    alias Helix.Story.Model.Story

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        step: Step.t,
        email: Story.Email.email
      }

    event_struct [:entity_id, :step, :email]

    @spec new(Step.t, Story.Email.email) ::
      t
    def new(step = %_{name: _, meta: _, entity_id: _}, email = %{id: _}) do
      %__MODULE__{
        entity_id: step.entity_id,
        step: step,
        email: email
      }
    end

    notify do
      @moduledoc """
      Logic of the notification that will be sent to the client once the event
      `StoryEmailSentEvent` is fired.
      """

      alias HELL.ClientUtils

      @event :story_email_sent

      def generate_payload(event, _socket) do
        contact_id = Step.get_contact(event.step) |> to_string()
        replies =
          event.step
          |> Step.get_replies_of(event.email.id)
          |> Enum.map(&to_string/1)

        data = %{
          step: to_string(event.step.name),
          contact_id: contact_id,
          replies: replies,
          email_id: event.email.id,
          meta: event.email.meta,
          timestamp: ClientUtils.to_timestamp(event.email.timestamp)
        }

        {:ok, data}
      end

      @doc """
      Notify the player on his own channel.
      """
      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
