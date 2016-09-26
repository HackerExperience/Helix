defmodule HELM.Process.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Process

  @primary_key {:process_id, :string, autogenerate: false}

  schema "processes" do
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
      do: Ecto.Changeset.put_change(changeset, :process_id, HELL.ID.generate("PROCESS")),
      else: changeset
  end
end
