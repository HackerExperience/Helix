defmodule HELM.Entity.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Account

  @primary_key {:entity_id, :string, autogenerate: false}
  
  schema "entities" do
    field :account_id, :string
    field :npc_id, :string
    field :clan_id, :string
    timestamps
  end

  @creation_fields ~w(account_id npc_id clan_id)

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_uuid()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: Ecto.Changeset.put_change(changeset, :entity_id, HELL.ID.generate("ENTY")),
      else: changeset
  end
end
