defmodule Helix.Notification.Model.Notification.Server do
  @moduledoc """
  Data definition for Server-related notifications.
  """

  use Ecto.Schema
  use HELL.ID, field: :notification_id

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Notification.Model.Code.Server.CodeEnum
  alias Helix.Notification.Model.Notification

  @type t ::
    %__MODULE__{
      notification_id: id,
      account_id: Account.id,
      server_id: Server.id,
      code: Notification.code,
      data: Notification.data,
      is_read: boolean,
      creation_time: DateTime.t
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params ::
    %{
      account_id: Account.id,
      server_id: Server.id,
      code: Notification.code,
      data: Notification.data
    }

  @type id_map :: %{account_id: Account.id, server_id: Server.id}
  @type id_map_input :: {Server.id, Account.id | Entity.id}

  @creation_fields [:account_id, :server_id, :code, :data]
  @required_fields [:account_id, :server_id, :code, :data, :creation_time]

  schema "notifications_server" do
    field :notification_id, ID,
      primary_key: true

    field :account_id, Account.ID
    field :server_id, Server.ID
    field :code, CodeEnum
    field :data, :map
    field :is_read, :boolean,
      default: false
    field :creation_time, :utc_datetime
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    heritage = build_heritage(params)

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_defaults()
    |> validate_required(@required_fields)
    |> put_pk(heritage, {:notification, :server})
  end

  @spec build_heritage(creation_params) ::
    Helix.ID.heritage
  defp build_heritage(params),
    do: %{grandparent: params.account_id, parent: params.server_id}

  @spec id_map(id_map_input) ::
    id_map
  def id_map({server_id = %Server.ID{}, account_id = %Account.ID{}}),
    do: %{account_id: account_id, server_id: server_id}

  def id_map({server_id = %Server.ID{}, entity_id = %Entity.ID{}}) do
    account_id = Account.ID.cast!(to_string(entity_id))
    %{account_id: account_id, server_id: server_id}
  end

  @spec put_defaults(changeset) ::
    changeset
  defp put_defaults(changeset) do
    changeset
    |> put_change(:creation_time, DateTime.utc_now())
  end

  query do

    alias Helix.Account.Model.Account
    alias Helix.Server.Model.Server
    alias Helix.Notification.Model.Notification

    @type methods :: :by_id | :by_account | :by_server

    @spec by_id(Queryable.t, Notification.Server.id) ::
      Queryable.t
    def by_id(query \\ Notification.Server, id),
      do: where(query, [n], n.notification_id == ^id)

    @spec by_account(Queryable.t, Account.id) ::
      Queryable.t
    def by_account(query \\ Notification.Server, account_id = %Account.ID{}),
      do: where(query, [n], n.account_id == ^account_id)

    @spec by_server(Queryable.t, Server.id) ::
      Queryable.t
    def by_server(query \\ Notification.Server, server_id = %Server.ID{}),
      do: where(query, [n], n.server_id == ^server_id)
  end

  order do

    @type methods :: :by_newest

    @spec by_newest(Queryable.t) ::
      Queryable.t
    def by_newest(query),
      do: order_by(query, [n], desc: n.creation_time)
  end
end
