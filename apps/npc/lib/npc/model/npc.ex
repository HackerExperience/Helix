defmodule HELM.NPC.Model.NPC do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6

  @primary_key {:npc_id, EctoNetwork.INET, autogenerate: false}

  schema "npcs" do
    timestamps
  end

  @creation_fields ~w()

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_primary_key()
  end

  defp put_primary_key(changeset) do
    if changeset.valid? do
      ip = IPv6.generate([0x0003])

      changeset
      |> cast(%{npc_id: ip}, ~w(npc_id))
    else
      changeset
    end
  end
end