defmodule HELM.Hardware.Motherboard.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELM.Hardware.Motherboard

  @primary_key {:motherboard_id, :string, autogenerate: false}

  schema "motherboards" do
    timestamps
  end

  def create_changeset do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_uid
  end

  defp put_uid(changeset) do
    if changeset.valid?,
      do: Changeset.put_change(changeset, :motherboard_id, HELL.ID.generate("MOBO")),
      else: changeset
  end
end
