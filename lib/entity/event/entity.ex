defmodule Helix.Entity.Event.Entity do

  import Helix.Event

  event Created do

    alias Helix.Account.Model.Account
    alias Helix.Universe.NPC.Model.NPC
    alias Helix.Entity.Model.Entity

    event_struct [:entity, :source]

    @type t ::
      %__MODULE__{
        entity: Entity.t,
        source: source
      }

    @typep source :: Account.t | NPC.t

    @spec new(Entity.t, source) ::
      t
    def new(entity = %Entity{}, source) do
      %__MODULE__{
        entity: entity,
        source: source
      }
    end
  end
end
