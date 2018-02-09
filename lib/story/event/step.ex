defmodule Helix.Story.Event.Step do

  import Helix.Event

  event Proceeded do
    @moduledoc """
    Story.StepProceeded is fired when the Player's current step is changed,
    moving from a previous step to the next one.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        previous_step: Step.t,
        next_step: Step.t
      }

    event_struct [:entity_id, :previous_step, :next_step]

    @spec new(Step.t, Step.t) ::
      t
    def new(prev_step = %_{entity_id: _}, next_step = %_{entity_id: _}) do
      %__MODULE__{
        entity_id: prev_step.entity_id,
        previous_step: prev_step,
        next_step: next_step
      }
    end

    notify do
      @moduledoc false

      @event :story_step_proceeded

      def generate_payload(event, _socket) do
        data = %{
          previous_step: to_string(event.previous_step.name),
          next_step: to_string(event.next_step.name)
        }

        {:ok, data}
      end

      @doc """
      Notifies only the player
      """
      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end

  event ActionRequested do
    @moduledoc """
    `StepActionRequestedEvent` is fired when a callback, declared at the Step
    definition, has been called as a reaction of a previously subscribed event.
    This callback may request that an action be performed on the step, like
    `:complete`, `:fail` or `:regenerate`.

    StepHandler will handle this event and perform the requested action.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step

    event_struct [:action, :entity_id, :contact_id]

    @type t ::
      %__MODULE__{
        action: Step.callback_action,
        entity_id: Entity.id,
        contact_id: Step.contact_id
      }

    @spec new(Step.callback_action, Entity.id, Step.contact_id) ::
      t
    def new(action, entity_id, contact_id) do
      %__MODULE__{
        action: action,
        entity_id: entity_id,
        contact_id: contact_id
      }
    end
  end
end
