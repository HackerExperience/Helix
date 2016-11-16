defmodule HELM.Server.Model.Server do

  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Server.Model.ServerType, as: MdlServerType, warn: false

  @primary_key {:server_id, EctoNetwork.INET, autogenerate: false}

  schema "servers" do
    belongs_to :type, MdlServerType,
      foreign_key: :server_type,
      references: :server_type,
      type: :string

    field :poi_id, EctoNetwork.INET
    field :motherboard_id, EctoNetwork.INET

    timestamps
  end

  @creation_fields ~w(server_type poi_id motherboard_id)
  @update_fields ~w(poi_id motherboard_id)

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> put_primary_key()
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
  end

  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0002, 0x0000, 0x0000])

    changeset
    |> cast(%{server_id: ip}, ~w(server_id))
  end
end