defmodule Helix.Log.Model.Revision do
  @moduledoc """
  Represents a change in the history of an in-game log.

  This record is opaque and should only be used on the `Helix.Log` domain to
  apply the stack mechanics of log forging
  """

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.LogType.LogEnum

  @type t :: %__MODULE__{
    log_id: Log.id,
    revision_id: id,
    entity_id: Entity.id,
    type: Log.type,
    data: Log.data,
    creation_time: DateTime.t,
  }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    entity_id: Entity.id,
    type: Log.type,
    data: Log.data,
    forge_version: pos_integer | nil,
  }

  @typedoc """
  `Revision.id` is a sequential, non-negative integer that acts as a counter.
  Each revision increments it, and if a LogRecoveryProcess removes a revision,
  it decrements.
  """
  @type id :: non_neg_integer

  @creation_fields [:entity_id, :type, :data, :forge_version, :revision_id]
  @required_fields [:log_id, :entity_id, :type, :data, :revision_id]

  @primary_key false
  schema "log_revisions" do
    field :log_id, Log.ID,
      primary_key: true
    field :revision_id, :integer,
      primary_key: true

    field :entity_id, Entity.ID

    field :type, LogEnum
    field :data, :map

    field :forge_version, :integer,
      default: nil

    field :creation_time, :utc_datetime

    belongs_to :log, Log,
      foreign_key: :log_id,
      references: :log_id,
      define_field: false
  end

  @spec create_changeset(Log.id, id, creation_params) ::
    changeset
  def create_changeset(log_id, revision_id, params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_change(:log_id, log_id)
    |> put_change(:revision_id, revision_id)
    |> put_change(:creation_time, DateTime.utc_now())
    |> validate_required(@required_fields)
  end

  query do

    alias Helix.Log.Model.Log
    alias Helix.Log.Model.Revision

    @spec by_log(Queryable.t, Log.id) ::
      Queryable.t
    def by_log(query \\ Revision, log_id),
      do: where(query, [lr], lr.log_id == ^log_id)

    @spec by_revision(Queryable.t, Revision.id) ::
      Queryable.t
    def by_revision(query, revision_id),
      do: where(query, [lr], lr.revision_id == ^revision_id)
  end
end
