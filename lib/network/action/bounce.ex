defmodule Helix.Network.Action.Bounce do

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Internal.Bounce, as: BounceInternal
  alias Helix.Network.Model.Bounce

  alias Helix.Network.Event.Bounce.Created, as: BounceCreatedEvent
  alias Helix.Network.Event.Bounce.CreateFailed, as: BounceCreateFailedEvent
  alias Helix.Network.Event.Bounce.Updated, as: BounceUpdatedEvent
  alias Helix.Network.Event.Bounce.UpdateFailed, as: BounceUpdateFailedEvent

  @type create_errors :: BounceInternal.create_errors
  @type update_errors :: BounceInternal.update_errors

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

  @spec update(Bounce.t, Bounce.name | nil, [Bounce.link] | nil) ::
    {:ok, Bounce.t, [BounceUpdatedEvent.t]}
    | {:error, update_errors, [BounceUpdateFailedEvent.t]}
  @doc """
  Updates a bounce. The bounce name, links or both may be updated.
  """
  def update(bounce, new_name, nil),
    do: do_update(bounce, new_name, bounce.links)
  def update(bounce, nil, new_links),
    do: do_update(bounce, bounce.name, new_links)
  def update(bounce, new_name, new_links),
    do: do_update(bounce, new_name, new_links)

  @spec do_update(Bounce.t, Bounce.name, [Bounce.link]) ::
    {:ok, Bounce.t, [BounceUpdatedEvent.t]}
    | {:error, update_errors, [BounceUpdateFailedEvent.t]}
  defp do_update(bounce = %Bounce{}, new_name, new_links) do
    case BounceInternal.update(bounce, name: new_name, links: new_links) do
      {:ok, bounce} ->
        event = BounceUpdatedEvent.new(bounce)
        {:ok, bounce, [event]}

      {:error, reason} ->
        event = BounceUpdateFailedEvent.new(bounce.entity_id, reason)
        {:error, reason, [event]}
    end
  end
end
