defmodule HELM.Entity.Model.Entity do

  use Ecto.Schema

  alias HELL.PK
  alias HELM.Entity.Model.EntityServer, as: MdlEntityServer, warn: false
  alias HELM.Entity.Model.EntityType, as: MdlEntityType, warn: false
  import Ecto.Changeset

  @type id :: String.t
  @type t :: %__MODULE__{
    entity_id: id,
    servers: [MdlEntityServer.t],
    type: MdlEntityType.t,
    entity_type: String.t,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @type creation_params :: %{
    entity_type: MdlEntityType.name}

  @creation_fields ~w/entity_type/a

  @primary_key false
  schema "entities" do
    field :entity_id, EctoNetwork.INET,
      primary_key: true

    has_many :servers, MdlEntityServer,
      foreign_key: :entity_id,
      references: :entity_id
    belongs_to :type, MdlEntityType,
      foreign_key: :entity_type,
      references: :entity_type,
      type: :string

    timestamps
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
end