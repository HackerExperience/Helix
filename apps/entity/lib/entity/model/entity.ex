defmodule HELM.Entity.Model.Entity do
  use Ecto.Schema
  alias Ecto.Changeset
  import Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Entity.Model.EntityServer, as: MdlEntityServer, warn: false
  alias HELM.Entity.Model.EntityType, as: MdlEntityType, warn: false

  @type create_params :: %{entity_type: String.t, reference_id: String.t}

  @primary_key {:entity_id, EctoNetwork.INET, autogenerate: false}
  @creation_fields ~w(entity_type reference_id)a

  schema "entities" do
    field :reference_id, EctoNetwork.INET

    has_many :servers, MdlEntityServer,
      foreign_key: :entity_id,
      references: :entity_id

    belongs_to :type, MdlEntityType,
      foreign_key: :entity_type,
      references: :entity_type,
      type: :string

    timestamps
  end

  @spec create_changeset(params :: create_params) :: Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> unique_constraint(:reference_id)
    |> put_primary_key()
  end

  @spec put_primary_key(changeset :: Changeset.t) :: Changeset.t
  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0001, 0x0000, 0x0000])

    changeset
    |> cast(%{entity_id: ip}, ~w(entity_id))
  end
end