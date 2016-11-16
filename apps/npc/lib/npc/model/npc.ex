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
    ip = IPv6.generate([0x0006, 0x0000, 0x0000])

    changeset
    |> cast(%{npc_id: ip}, ~w(npc_id))
  end
end