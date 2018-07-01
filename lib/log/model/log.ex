defmodule Helix.Log.Model.Log do

  use Ecto.Schema
  use HELL.ID, field: :log_id

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Revision

  @type message :: String.t

  @type t :: %__MODULE__{
    log_id: id,
    server_id: Server.id,
    entity_id: Entity.id,
    message: message,
    crypto_version: pos_integer | nil,
    revisions: term,
    creation_time: DateTime.t
  }

  @type creation_params :: %{
    :server_id => Server.idtb,
    :entity_id => Entity.idtb,
    :message => String.t,
    optional(:crypto_version) => pos_integer | nil,
    optional(:forge_version) => pos_integer | nil,
    optional(atom) => any
  }

  @type update_params :: %{
    optional(:crypto_version) => pos_integer | nil,
    optional(:message) => String.t
  }

  @creation_fields ~w/server_id entity_id message/a
  @update_fields ~w/message crypto_version/a

  @required_fields ~w/server_id entity_id message/a

  schema "logs" do
    field :log_id, ID,
      primary_key: true

    field :server_id, Server.ID
    field :entity_id, Entity.ID

    field :message, :string
    field :crypto_version, :integer

    field :creation_time, :utc_datetime

    has_many :revisions, Revision,
      foreign_key: :log_id,
      references: :log_id,
      on_delete: :delete_all,
      on_replace: :delete
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    heritage = build_heritage(params)
    revision = Revision.changeset(%Revision{}, params)
    revision_time = get_change(revision, :creation_time)

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> put_assoc(:revisions, [revision])
    |> put_change(:creation_time, revision_time)
    |> put_pk(heritage, :log)
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_required(@required_fields)
    |> validate_number(:crypto_version, greater_than_or_equal_to: 0)
  end

  @spec build_heritage(creation_params) ::
    Helix.ID.heritage
  defp build_heritage(params),
    do: %{parent: params.server_id}

  query do

    alias Helix.Entity.Model.Entity
    alias Helix.Server.Model.Server
    alias Helix.Log.Model.Log
    alias Helix.Log.Model.LogTouch

    @spec by_id(Queryable.t, Log.idtb) ::
      Queryable.t
    def by_id(query \\ Log, id),
      do: where(query, [l], l.log_id == ^id)

    @spec edited_by_entity(Queryable.t, Entity.idtb) ::
      Queryable.t
    def edited_by_entity(query \\ Log, id) do
      query
      |> join(:inner, [l], lt in LogTouch, lt.log_id == l.log_id)
      |> where([l, ..., lt], lt.entity_id == ^id)
    end

    @spec by_server(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_server(query \\ Log, id),
      do: where(query, [l], l.server_id == ^id)

    @spec by_message(Queryable.t, String.t) ::
      Queryable.t
    def by_message(query \\ Log, message),
      do: where(query, [l], like(l.message, ^message))

    @spec order_by_newest(Queryable.t) ::
      Queryable.t
    def order_by_newest(query),
      do: order_by(query, [l], desc: l.creation_time)
  end
end
