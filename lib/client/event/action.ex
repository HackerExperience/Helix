import Helix.Event

defmodule Helix.Client.Event.Action do

  event Performed do
    @moduledoc """
    `ClientActionPerformedEvent` is emitted when the client performed a custom
    action that should be tracked by the backend for a specific behaviour.
    Examples include the tutorial quest, which awaits for the player to open
    apps in order to proceed with the storyline.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Client.Model.Client

    event_struct [:client, :entity_id, :action]

    @type t ::
      %__MODULE__{
        client: Client.t,
        entity_id: Entity.id,
        action: Client.action
      }

    @spec new(Client.t, Entity.id, Client.action) ::
      t
    def new(client, entity_id, action) do
      %__MODULE__{
        client: client,
        entity_id: entity_id,
        action: action
      }
    end
  end
end
