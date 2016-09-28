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

  @creation_fields ~w(server_type entity_id poi_id motherboard_id)
  @update_fields ~w(poi_id motherboard_id)

  def create_changeset(params \\ :empty) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_default_server_type
    |> generic_validations
    |> put_uuid()
  end

  def update_changeset(params \\ :empty) do
    %__MODULE__{}
    |> cast(params, @update_fields)
    |> generic_validations
  end

  defp generic_validations(changeset) do
    if not Map.has_key?(changeset, :server_type) do
      changeset
      |> validate_format(changeset, :server_type, ~r/mobile|server/)
    else
      changeset
    end
  end

  defp put_default_server_type(changeset) do
    with true  <- changeset.valid?,
         false <- Map.has_key?(changeset, :server_type)
    do
      Changeset.put_change(changeset, :server_type, "desktop")
    else
      _ -> changeset
    end
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
