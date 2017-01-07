defmodule Helix.Server.Model.Server do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Server.Model.ServerType, as: MdlServerType, warn: false
  import Ecto.Changeset

  @type id :: PK.t
  @type t :: %__MODULE__{
    server_id: id,
    type: MdlServerType.t,
    server_type: String.t,
    poi_id: PK.t,
    motherboard_id: PK.t,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @type creation_params :: %{
    :server_type => String.t,
    optional(:motherboard_id) => PK.t,
    optional(:poi_id) => PK.t
  }
  @type update_params :: %{
    optional(:poi_id) => PK.t | nil,
    optional(:motherboard_id) => PK.t | nil
  }

  @creation_fields ~w/server_type poi_id motherboard_id/a
  @update_fields ~w/poi_id motherboard_id/a

  @primary_key false
  schema "servers" do
    field :server_id, EctoNetwork.INET,
      primary_key: true

    field :poi_id, EctoNetwork.INET
    field :motherboard_id, EctoNetwork.INET

    belongs_to :type, MdlServerType,
      foreign_key: :server_type,
      references: :server_type,
      type: :string

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> put_primary_key()
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0002, 0x0000, 0x0000])

    changeset
    |> cast(%{server_id: ip}, [:server_id])
  end
end