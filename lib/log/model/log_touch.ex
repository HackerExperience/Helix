defmodule Helix.Log.Model.LogTouch do
  @moduledoc """
  Links entities to logs

  This model caches the relationship of entities that edited (or created) a log.

  Does so to allow the client to display all logs that a certain user edited at
  some point of history (even if their revision was removed)
  """

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