defmodule Helix.Log.Model.Revision do
  @moduledoc false

  # This record is opaque and should only be used on the Log domain to apply the
  # stack mechanics of log forging

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Log.Model.Log

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :entity_id => PK.t,
    :message => String.t,
    optional(:forge_version) => pos_integer | nil,
    optional(any) => any
  }

  @creation_fields ~w/entity_id message forge_version/a

  @primary_key false
  @ecto_autogenerate {:revision_id, {PK, :pk_for, [:log_revision]}}
  schema "revisions" do
    field :revision_id, PK,
      primary_key: true

    field :log_id, PK
    field :entity_id, PK

    field :message, :string
    field :forge_version, :integer

    belongs_to :log, Log,
      foreign_key: :log_id,
      references: :log_id,
      define_field: false

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @spec create(Log.t, PK.t, String.t, pos_integer | nil) ::
    Ecto.Changeset.t
  def create(log, entity, message, forge \\ nil) do
    params = %{
      entity_id: entity,
      message: message,
      forge_version: forge
    }

    changeset = changeset(%__MODULE__{}, params)
    message = get_change(changeset, :message)

    log = Log.update_changeset(log, %{message: message})

    put_assoc(changeset, :log, log)
  end

  @spec changeset(t | Ecto.Changeset.t, creation_params) ::
    Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, @creation_fields)
    |> validate_required([:entity_id, :message])
    |> validate_number(:forge_version, greater_than: 0)
  end

  defmodule Query do

    alias Ecto.Queryable
    alias HELL.PK
    alias Helix.Log.Model.Log
    alias Helix.Log.Model.Revision

    import Ecto.Query

    @spec from_log(Queryable.t, Log.t | PK.t) ::
      Queryable.t
    def from_log(query \\ Revision, log_or_id)
    def from_log(query, %Log{log_id: id}),
      do: from_log(query, id)
    def from_log(query, id),
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
