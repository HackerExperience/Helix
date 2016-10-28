defmodule HELM.Process.Model.Process do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID

  @primary_key {:process_id, :binary_id, autogenerate: false}

  schema "processes" do
    timestamps
  end

  @creation_fields ~w()

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_uuid()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: put_change(changeset, :process_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("04")
end