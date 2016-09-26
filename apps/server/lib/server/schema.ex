defmodule HELM.Server.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Server

  @primary_key {:server_id, :string, autogenerate: false}

  schema "servers" do
    timestamps
  end

  @creation_fields ~w()

  def create_changeset(params \\ :empty) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_uuid()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: Ecto.Changeset.put_change(changeset, :server_id, HELL.ID.generate("SERVER")),
      else: changeset
  end
end
