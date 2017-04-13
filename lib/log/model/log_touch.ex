defmodule Helix.Log.Model.LogTouch do
  @moduledoc false

  # Links entities to logs

  # This model caches the relationship of entities that edited (or created) a
  # log.

  # Does so to allow the client to display all logs that a certain user edited
  # at some point of history (even if their revision was removed)

  # This record is opaque and should only be used on the Log domain to mark logs
  # as touched by a certain entity

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Log.Model.Log

  import Ecto.Changeset

  @primary_key false
  schema "log_touches" do
    field :log_id, PK,
      primary_key: true
    field :entity_id, PK,
      primary_key: true

    belongs_to :log, Log,
      references: :log_id,
      foreign_key: :log_id,
      define_field: false
  end

  @spec create(Log.t, PK.t) ::
    Ecto.Changeset.t
  def create(log, entity) do
    %__MODULE__{}
    |> cast(%{entity_id: entity}, [:entity_id])
    |> put_assoc(:log, log)
  end
end
