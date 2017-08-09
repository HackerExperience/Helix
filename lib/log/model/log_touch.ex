defmodule Helix.Log.Model.LogTouch do
  @moduledoc """
  Links entities to logs.

  This model caches the relationship of entities that edited (or created) a log.

  Does so to allow the client to display all logs that a certain user edited at
  some point of history (even if their revision was removed).

  This record is opaque and should only be used on the `Helix.Log` domain to
  mark logs as touched by a certain entity.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Model.Log

  @type t :: %__MODULE__{
    log_id: Log.id,
    entity_id: Entity.id,
    log: term
  }

  @primary_key false
  schema "log_touches" do
    field :log_id, Log.ID,
      primary_key: true
    field :entity_id, Entity.ID,
      primary_key: true

    belongs_to :log, Log,
      references: :log_id,
      foreign_key: :log_id,
      define_field: false
  end

  @spec create(Log.t, Entity.idtb) ::
    Changeset.t
  def create(log, entity) do
    %__MODULE__{}
    |> cast(%{entity_id: entity}, [:entity_id])
    |> put_assoc(:log, log)
  end
end
