defmodule Helix.Story.Model.Story.Manager do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @type t ::
    %__MODULE__{
      entity_id: Entity.id,
      server_id: Server.id,
      network_id: Network.id
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params ::
    %{
      entity_id: Entity.id,
      server_id: Server.id,
      network_id: Network.id
    }

  @creation_fields [:entity_id, :server_id, :network_id]
  @required_fields [:entity_id, :server_id, :network_id]

  @primary_key false
  schema "story_manager" do
    field :entity_id, Entity.ID,
      primary_key: true

    field :server_id, Server.ID
    field :network_id, Network.ID
  end

  @spec create(creation_params) ::
    changeset
  def create(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  query do

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Story

    @spec by_entity(Queryable.t, Entity.id) ::
      Queryable.t
    def by_entity(query \\ Story.Manager, entity_id),
      do: where(query, [sm], sm.entity_id == ^entity_id)
  end
end
