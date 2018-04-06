import Helix.Event

# Note to self: When implementing `web2`, use a macro that generates the
# skeleton of this event and each client then specializes it.
defmodule Helix.Client.Web1.Event.Action do

  event Performed do
    @moduledoc """
    `Web1ActionPerformedEvent` is emitted when the client performed a custom
    action that should be tracked by the backend for a specific behaviour.
    Examples include the tutorial quest, which awaits for the player to open
    apps in order to proceed with the storyline.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Client.Web1.Model.Web1

    event_struct [:entity_id, :action]

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        action: Web1.action
      }

    @spec new(Entity.id, Web1.action) ::
      t
    def new(entity_id, action) do
      %__MODULE__{
        entity_id: entity_id,
        action: action
      }
    end
  end
end
