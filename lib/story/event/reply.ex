defmodule Helix.Story.Event.Reply do

  defmodule Sent do

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
  end
end
