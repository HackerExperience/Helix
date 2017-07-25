defmodule Helix.Log.Model.Log do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Log.Model.Revision

  @type id :: PK.t
  @type t :: %__MODULE__{
    log_id: id,
    server_id: PK.t,
    entity_id: PK.t,
    message: String.t,
    crypto_version: pos_integer | nil,
    revisions: [Revision.t],
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :server_id => PK.t,
    :entity_id => PK.t,
    :message => String.t,
    optional(:crypto_version) => pos_integer | nil,
    optional(:forge_version) => pos_integer | nil
  }

  @type update_params :: %{
    optional(:crypto_version) => pos_integer | nil,
    optional(:message) => pos_integer | nil
  }

  @creation_fields ~w/server_id entity_id message/a
  @update_fields ~w/message crypto_version/a

  @required_fields ~w/server_id entity_id message/a

  @primary_key false
  @ecto_autogenerate {:log_id, {PK, :pk_for, [:log_log]}}
  schema "logs" do
    field :log_id, PK,
      primary_key: true

    field :server_id, PK
    field :entity_id, PK

    field :message, :string
    field :crypto_version, :integer

    has_many :revisions, Revision,
      foreign_key: :log_id,
      references: :log_id,
      on_delete: :delete_all,
      on_replace: :delete

    timestamps()
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    revision = Revision.changeset(%Revision{}, params)

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> put_assoc(:revisions, [revision])
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_required(@required_fields)
    |> validate_number(:crypto_version, greater_than: 0)
  end

  defmodule Query do

    import Ecto.Query, only: [join: 5, order_by: 3, where: 3]

    alias Ecto.Queryable
    alias HELL.PK
    alias Helix.Entity.Model.Entity
    alias Helix.Server.Model.Server
    alias Helix.Log.Model.Log
    alias Helix.Log.Model.LogTouch

    @spec edited_by_entity(Queryable.t, Entity.id) ::
      Queryable.t
    def edited_by_entity(query \\ Log, entity_id) do
      query
      |> join(:inner, [l], lt in LogTouch, lt.log_id == l.log_id)
      |> where([l, ..., lt], lt.entity_id == ^entity_id)
    end

    @spec by_id(Queryable.t, Log.id) ::
      Queryable.t
    def by_id(query \\ Log, id),
      do: where(query, [l], l.log_id == ^id)

    @spec by_server_id(Queryable.t, Server.id) ::
      Queryable.t
    def by_server_id(query \\ Log, server_id),
      do: where(query, [l], l.server_id == ^server_id)

    @spec by_message(Queryable.t, String.t) ::
      Queryable.t
    def by_message(query \\ Log, message),
      do: where(query, [l], like(l.message, ^message))

    @spec order_by_newest(Queryable.t) ::
      Queryable.t
    def order_by_newest(query \\ Log),
      do: order_by(query, [l], desc: l.inserted_at)
  end
end
