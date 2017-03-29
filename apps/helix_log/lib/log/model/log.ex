defmodule Helix.Log.Model.Log do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Log.Model.Revision

  import Ecto.Changeset

  @type t :: %__MODULE__{
    log_id: PK.t,
    server_id: PK.t,
    entity_id: PK.t,
    message: String.t,
    crypto_version: non_neg_integer | nil,
    revisions: [Revision.t],
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :server_id => PK.t,
    :entity_id => PK.t,
    :message => String.t,
    optional(:crypto_version) => non_neg_integer | nil,
    optional(:forge_version) => non_neg_integer | nil
  }

  @type update_params :: %{
    optional(:crypto_version) => non_neg_integer | nil,
    optional(:message) => non_neg_integer | nil
  }

  @creation_fields ~w/server_id entity_id message/a
  @update_fields ~w/message crypto_version/a

  @required_fields ~w/server_id entity_id message/a

  @primary_key false
  @ecto_autogenerate {:log_id, {PK, :pk_for, [__MODULE__]}}
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

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> prepare_changes(fn changeset ->
      revisions = [
        %{
          entity_id: params[:entity_id],
          message: params[:message],
          forge_version: params[:forge_version]
        }
      ]

      changeset
      |> cast(%{revisions: revisions}, [])
      |> cast_assoc(:revisions, with: fn _, params ->
        Revision.create_changeset(params)
      end)
    end)
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_required(@required_fields)
    |> validate_number(:crypto_version, greater_than: 0)
  end

  defmodule Query do

    alias Helix.Log.Model.Log
    alias Helix.Log.Model.LogTouch

    import Ecto.Query, only: [join: 5, order_by: 3, where: 3]

    @spec edited_by_entity(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def edited_by_entity(query \\ Log, entity_id) do
      query
      |> join(:inner, [l], lt in LogTouch, lt.log_id == l.log_id)
      |> where([l, lt], lt.entity_id == ^entity_id)
    end

    @spec by_server(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_server(query \\ Log, server_id) do
      where(query, [l], l.server_id == ^server_id)
    end

    @spec order_by_newest(Ecto.Queryable.t) :: Ecto.Queryable.t
    def order_by_newest(query \\ Log) do
      order_by(query, [l], desc: l.inserted_at)
    end
  end
end
