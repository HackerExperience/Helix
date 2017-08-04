defmodule Helix.Entity.Model.EntityServer do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Entity.Model.Entity

  @type t :: %__MODULE__{
    server_id: Server.id,
    entity_id: Entity.id,
    entity: Entity.t
  }

  @type creation_params :: %{
    server_id: Server.idtb,
    entity_id: Entity.idtb
  }

  @creation_fields ~w/server_id entity_id/a

  @primary_key false
  schema "entity_servers" do
    field :server_id, Server.ID,
      primary_key: true
    field :entity_id, Entity.ID,
      primary_key: true

    belongs_to :entity, Entity,
      foreign_key: :entity_id,
      references: :entity_id,
      define_field: false,
      primary_key: true
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Server.Model.Server
    alias Helix.Entity.Model.Entity
    alias Helix.Entity.Model.EntityServer

    @spec by_entity(Queryable.t, Entity.idtb) ::
      Queryable.t
    def by_entity(query \\ EntityServer, id),
      do: where(query, [es], es.entity_id == ^id)

    @spec by_server(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_server(query \\ EntityServer, id),
      do: where(query, [es], es.server_id == ^id)
  end
end
