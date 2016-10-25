defmodule HELM.Server.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  alias HELM.Server.Type.Schema, as: ServerTypeSchema

  @primary_key {:server_id, :string, autogenerate: false}

  schema "servers" do
    belongs_to :server_types, ServerTypeSchema,
      foreign_key: :server_type,
      references: :server_type,
      type: :string

    field :poi_id, :string
    field :motherboard_id, :string

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

  def update_changeset(struct, params \\ :empty) do
    struct
    |> cast(params, @update_fields)
  end

  defp put_uuid(changeset) do
    if changeset.valid? do
      server_id = HELL.ID.generate("SRVR")
      Changeset.put_change(changeset, :server_id, server_id)
    else
      changeset
    end
  end
end
