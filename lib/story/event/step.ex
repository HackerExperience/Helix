defmodule Helix.Story.Event.Step do

  defmodule Proceeded do

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        previous_step: Step.step_name,
        next_step: Step.step_name
      }

    @enforce_keys [:entity_id, :previous_step, :next_step]
    defstruct [:entity_id, :previous_step, :next_step]
  end
end
