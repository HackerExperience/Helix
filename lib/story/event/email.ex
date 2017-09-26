defmodule Helix.Story.Event.Email do

  defmodule Sent do

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
  end
end
