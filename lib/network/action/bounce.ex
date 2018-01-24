defmodule Helix.Network.Action.Bounce do

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Internal.Bounce, as: BounceInternal
  alias Helix.Network.Model.Bounce

  alias Helix.Network.Event.Bounce.Created, as: BounceCreatedEvent
  alias Helix.Network.Event.Bounce.CreateFailed, as: BounceCreateFailedEvent

  @type create_errors :: BounceInternal.create_errors

  @spec create(Entity.id, Bounce.name, [Bounce.link]) ::
    {:ok, Bounce.t, [BounceCreatedEvent.t]}
    | {:error, create_errors, [BounceCreateFailedEvent.t]}
  @doc """
  Creates a new bounce
  """
  def create(entity_id, name, links) do
    case BounceInternal.create(entity_id, name, links) do
      {:ok, bounce} ->
        {:ok, bounce, [BounceCreatedEvent.new(bounce)]}

      {:error, reason} ->
        {:error, reason, [BounceCreateFailedEvent.new(entity_id, reason)]}
    end
  end
end
