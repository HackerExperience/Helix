defmodule HELM.Server.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELM.Server

  @primary_key {:server_id, :string, autogenerate: false}

  schema "servers" do
    field :server_type, :string, default: "desktop"
    field :entity_id, :string
    field :poi_id, :string
    field :motherboard_id, :string

    timestamps
  end

  @creation_fields ~w(entity_id server_type poi_id motherboard_id)
  @update_fields ~w(poi_id motherboard_id)

  def create_changeset(params \\ :empty) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_id)
    |> update_change(:server_type, &default_server_type/1)
    |> validate_server_type
    |> put_uuid
  end

  def update_changeset(params \\ :empty) do
    %__MODULE__{}
    |> cast(params, @update_fields)
    |> validate_server_type
  end

  defp default_server_type(got) do
    if is_nil(got) or got == "",
      do: "desktop",
      else: got
  end

  defp validate_server_type(changeset) do
    validate_format(changeset, :server_type, ~r/mobile|server/)
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
