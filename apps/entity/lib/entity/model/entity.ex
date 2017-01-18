defmodule Helix.Entity.Model.Entity do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Model.EntityType
  import Ecto.Changeset

  @type id :: String.t
  @type t :: %__MODULE__{
    entity_id: id,
    servers: [EntityServer.t],
    type: EntityType.t,
    entity_type: String.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    entity_type: EntityType.name}

  @creation_fields ~w/entity_type/a

  @primary_key false
  schema "entities" do
    field :entity_id, HELL.PK,
      primary_key: true

    has_many :servers, EntityServer,
      foreign_key: :entity_id,
      references: :entity_id
    belongs_to :type, EntityType,
      foreign_key: :entity_type,
      references: :entity_type,
      type: :string

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:entity_type])
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    pk =
      changeset
      |> get_field(:entity_type)
      |> generate_pk()

    cast(changeset, %{entity_id: pk}, [:entity_id])
  end

  @spec generate_pk(String.t) :: PK.t
  defp generate_pk("account"),
    do: PK.generate([0x0000, 0x0000, 0x0000])
  defp generate_pk("npc"),
    do: PK.generate([0x0006, 0x0000, 0x0000])
  defp generate_pk("clan"),
    do: PK.generate([0x0007, 0x0000, 0x0000])
end