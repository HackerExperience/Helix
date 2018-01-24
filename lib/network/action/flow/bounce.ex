defmodule Helix.Network.Action.Flow.Bounce do

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Action.Bounce, as: BounceAction
  alias Helix.Network.Model.Bounce

  @spec create(Entity.id, Bounce.name, [Bounce.link], Event.relay) ::
    {:ok, Bounce.t}
    | {:error, BounceAction.create_errors}
  @doc """
  Creates a new bounce with `name`, owned by `entity_id`, with the given `links`

  Emits: `BounceCreatedEvent`, `BounceCreateFailedEvent`
  """
  def create(entity_id, name, links, relay) do
    case BounceAction.create(entity_id, name, links) do
      {:ok, bounce, events} ->
        Event.emit(events, from: relay)

        {:ok, bounce}

      {:error, reason, events} ->
        Event.emit(events, from: relay)

        {:error, reason}
    end
  end
end
