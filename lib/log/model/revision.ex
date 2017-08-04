defmodule Helix.Log.Model.Revision do
  @moduledoc false

  # This record is opaque and should only be used on the Log domain to apply the
  # stack mechanics of log forging

  use Ecto.Schema
  use HELL.ID, field: :revision_id, meta: [0x0030, 0x0001]

  import Ecto.Changeset

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
    inserted_at: DateTime.t
  }

  @type creation_params :: %{
    :entity_id => Entity.idtb,
    :message => String.t,
    optional(:forge_version) => pos_integer | nil
  }

  @creation_fields ~w/entity_id message forge_version/a

  schema "revisions" do
    field :revision_id, ID,
      primary_key: true

    field :log_id, Log.ID
    field :entity_id, Entity.ID

    field :message, :string
    field :forge_version, :integer

    belongs_to :log, Log,
      foreign_key: :log_id,
      references: :log_id,
      define_field: false

    timestamps(type: :utc_datetime, updated_at: false)
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
  end

  @spec changeset(%__MODULE__{} | Changeset.t, creation_params) ::
    Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, @creation_fields)
    |> validate_required([:entity_id, :message])
    |> validate_number(:forge_version, greater_than: 0)
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Log.Model.Log
    alias Helix.Log.Model.Revision

    @spec by_log(Queryable.t, Log.idtb) ::
      Queryable.t
    def by_log(query \\ Revision, id),
      do: where(query, [r], r.log_id == ^id)

    @spec last(Queryable.t, non_neg_integer) ::
      Queryable.t
    def last(query \\ Revision, n) do
      query
      # TODO: Use revision id to order (and remove inserted_at)
      |> order_by([r], desc: r.inserted_at)
      |> limit(^n)
    end
  end
end
