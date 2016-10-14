defmodule HELM.Software.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  alias HELM.Software.Type.Schema, as: SoftwareTypeSchema

  @primary_key {:software_id, :string, autogenerate: false}

  schema "softwares" do
    timestamps
  end

  @creation_fields ~w//a
  @update_fields ~w//a

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_uuid
  end

  def update_changeset(struct, params \\ :empty) do
    struct
    |> cast(params, @update_fields)
  end

  defp put_uuid(changeset) do
    if changeset.valid? do
      software_id = HELL.ID.generate("SOFT")
      Changeset.put_change(changeset, :software_id, software_id)
    else
      changeset
    end
  end
end
