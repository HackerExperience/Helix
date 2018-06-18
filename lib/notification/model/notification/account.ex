defmodule Helix.Notification.Model.Notification.Account do

  use Ecto.Schema
  use HELL.ID, field: :notification_id, meta: [0x0050, 0x0001]

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Notification.Model.Code.Account.CodeEnum

  @creation_fields [:account_id, :code, :data]
  @required_fields [:account_id, :code, :data, :creation_time]

  schema "notifications_account" do
    field :notification_id, ID,
      primary_key: true

    field :account_id, Account.ID
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

  def notification_map(entity_id = %Entity.ID{}),
    do: %{account_id: Account.ID.cast!(to_string(entity_id))}
  def notification_map(account_id = %Account.ID{}),
    do: %{account_id: account_id}

  defp put_defaults(changeset) do
    changeset
    |> put_change(:creation_time, DateTime.utc_now())
  end

  query do

    alias Helix.Account.Model.Account
    alias Helix.Notification.Model.Notification

    @spec by_id(Queryable.t, Notification.Account.id) ::
      Queryable.t
    def by_id(query \\ Notification.Account, id),
      do: where(query, [n], n.notification_id == ^id)

    @spec by_account(Queryable.t, Account.id) ::
      Queryable.t
    def by_account(query \\ Notification.Account, account_id),
      do: where(query, [n], n.account_id == ^account_id)
  end
end
