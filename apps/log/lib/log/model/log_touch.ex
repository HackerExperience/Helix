defmodule Helix.Log.Model.LogTouch do

  use Ecto.Schema

  alias HELL.PK

  import Ecto.Changeset

  @primary_key false
  schema "log_touches" do
    field :log_id, PK,
      primary_key: true
    field :entity_id, PK,
      primary_key: true
  end

  def changeset(struct, params),
    do: cast(struct, params, [:log_id, :entity_id])
end