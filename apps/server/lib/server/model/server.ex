defmodule HELM.Server.Model.Server do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID
  alias HELM.Server.Model.ServerType, as: MdlServerType, warn: false

  @primary_key {:server_id, :binary_id, autogenerate: false}

  schema "servers" do
    belongs_to :server_types, MdlServerType,
      foreign_key: :server_type,
      references: :server_type,
      type: :string

    field :poi_id, :binary_id
    field :motherboard_id, :binary_id

    timestamps
  end

  @creation_fields ~w(server_type poi_id motherboard_id)
  @update_fields ~w(poi_id motherboard_id)

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> put_uuid
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: put_change(changeset, :server_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("05")
end