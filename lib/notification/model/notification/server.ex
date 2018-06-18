defmodule Helix.Notification.Model.Notification.Server do

  use Ecto.Schema
  use HELL.ID, field: :notification_id, meta: [0x0050, 0x0002]

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias HELL.IPv4
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Notification.Model.Code.Server.CodeEnum

  @creation_fields [:account_id, :server_id, :network_id, :ip, :code, :data]

  @required_fields [
    :account_id,
    :server_id,
    :network_id,
    :ip,
    :code,
    :data,
    :creation_time
  ]

  schema "notifications_server" do
    field :notification_id, ID,
      primary_key: true

    field :account_id, Account.ID
    field :server_id, Server.ID
    field :network_id, Network.ID
    field :ip, IPv4
    field :code, CodeEnum
    field :data, :map
    field :is_read, :boolean
    field :creation_time, :utc_datetime
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_defaults()
    |> validate_required(@required_fields)
  end

  def notification_map(
    %{account_id: entity_id = %Entity.ID{}, server_id: server_id}
  ) do
    %{account_id: Account.ID.cast!(to_string(entity_id)), server_id: server_id}
  end

  def notification_map(
    map = %{account_id: %Account.ID{}, server_id: %Server.ID{}}
  ) do
    map
  end

  defp put_defaults(changeset) do
    changeset
    |> put_change(:creation_time, DateTime.utc_now())
  end

  query do

    alias Helix.Account.Model.Account
    alias Helix.Server.Model.Server
    alias Helix.Notification.Model.Notification

    @spec by_id(Queryable.t, Notification.Server.id) ::
      Queryable.t
    def by_id(query \\ Notification.Server, id),
      do: where(query, [n], n.notification_id == ^id)

    @spec by_account(Queryable.t, Account.id) ::
      Queryable.t
    def by_account(query \\ Notification.Server, account_id),
      do: where(query, [n], n.account_id == ^account_id)

    @spec by_server(Queryable.t, Server.id) ::
      Queryable.t
    def by_server(query \\ Notification.Server, server_id),
      do: where(query, [n], n.server_id == ^server_id)
  end
end
