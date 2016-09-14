defmodule HELM.Entity.Model do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  schema "entities" do
    field :account_id, :string
    field :npc_id, :string
    field :clan_id, :string

    timestamps
  end

  @required_fields ~w()
  @optional_fields ~w(account_id npc_id clan_id)

  def changeset(entity, params \\ :empty) do
    entity
    |> cast(params, @required_fields, @optional_fields)
  end

end
