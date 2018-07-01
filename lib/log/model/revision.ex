defmodule Helix.Log.Model.Revision do
  @moduledoc """
  Represents a change in the history of an in-game log.

  This record is opaque and should only be used on the `Helix.Log` domain to
  apply the stack mechanics of log forging
  """

  use Ecto.Schema
  use HELL.ID, field: :revision_id

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Model.Log

  @type t :: %__MODULE__{
    revision_id: id,
    log_id: Log.id,
    entity_id: Entity.id,
    message: String.t,
    forge_version: pos_integer | nil,
    log: term,
    creation_time: DateTime.t,
  }

  @type creation_params :: %{
    :entity_id => Entity.idtb,
    :message => String.t,
    optional(:forge_version) => pos_integer | nil,
    optional(atom) => any
  }

  @creation_fields ~w/entity_id message forge_version/a

  schema "revisions" do
    field :revision_id, ID,
      primary_key: true

    field :log_id, Log.ID
    field :entity_id, Entity.ID

    field :message, :string
    field :forge_version, :integer

    field :creation_time, :utc_datetime

    belongs_to :log, Log,
      foreign_key: :log_id,
      references: :log_id,
      define_field: false
  end

  @spec create(Log.t, Entity.idtb, String.t, pos_integer | nil) ::
    Changeset.t
  def create(log, entity, message, forge \\ nil) do
    params = %{
      entity_id: entity,
      message: message,
      forge_version: forge
    }

    log = Log.update_changeset(log, %{message: message})

    %__MODULE__{}
    |> changeset(params)
    |> put_assoc(:log, log)
    |> put_pk(%{}, {:log, :revision})  # Correct heritage is TODO
  end

  @spec changeset(%__MODULE__{} | Changeset.t, creation_params) ::
    Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, @creation_fields)
    |> validate_required([:entity_id, :message])
    |> validate_number(:forge_version, greater_than: 0)
    |> put_change(:creation_time, DateTime.utc_now())
    |> put_pk(%{}, {:log, :revision})  # Correct heritage is TODO
  end

  query do

    alias Helix.Entity.Model.Entity
    alias Helix.Log.Model.Log
    alias Helix.Log.Model.Revision

    @spec by_id(Queryable.t, Revision.idtb) ::
      Queryable.t
    def by_id(query \\ Revision, id),
      do: where(query, [r], r.revision_id == ^id)

    @spec by_log(Queryable.t, Log.idtb) ::
      Queryable.t
    def by_log(query \\ Revision, id),
      do: where(query, [r], r.log_id == ^id)

    @spec by_entity(Queryable.t, Entity.idtb) ::
      Queryable.t
    def by_entity(query \\ Revision, id),
      do: where(query, [r], r.entity_id == ^id)

    @spec select_count(Queryable.t) ::
      Queryable.t
    def select_count(query \\ Revision),
      do: select(query, [r], count(r.revision_id))

    @spec last(Queryable.t, non_neg_integer) ::
      Queryable.t
    def last(query, n) do
      query
      |> order_by([r], desc: r.creation_time)
      |> limit(^n)
    end
  end
end
