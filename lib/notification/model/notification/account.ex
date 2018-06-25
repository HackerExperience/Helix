defmodule Helix.Notification.Model.Notification.Account do
  @moduledoc """
  Data definition for Account-related notifications.

  Probably one of the simplest notification classes; no secrets here.
  """

  use Ecto.Schema
  use HELL.ID, field: :notification_id, meta: [0x0050, 0x0001]

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Notification.Model.Code.Account.CodeEnum
  alias Helix.Notification.Model.Notification

  @type t ::
    %__MODULE__{
      notification_id: id,
      account_id: Account.id,
      code: Notification.code,
      data: Notification.data,
      is_read: boolean,
      creation_time: DateTime.t
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params ::
    %{
      account_id: Account.id,
      code: Notification.code,
      data: Notification.data
    }

  @type id_map :: %{account_id: Account.id}
  @type id_map_input :: Entity.id | Account.id

  @creation_fields [:account_id, :code, :data]
  @required_fields [:account_id, :code, :data, :creation_time]

  schema "notifications_account" do
    field :notification_id, ID,
      primary_key: true

    field :account_id, Account.ID
    field :code, CodeEnum
    field :data, :map
    field :is_read, :boolean,
      default: false
    field :creation_time, :utc_datetime
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_defaults()
    |> validate_required(@required_fields)
  end

  @spec id_map(id_map_input) ::
    id_map
  def id_map(entity_id = %Entity.ID{}),
    do: %{account_id: Account.ID.cast!(to_string(entity_id))}
  def id_map(account_id = %Account.ID{}),
    do: %{account_id: account_id}

  @spec put_defaults(changeset) ::
    changeset
  defp put_defaults(changeset) do
    changeset
    |> put_change(:creation_time, DateTime.utc_now())
  end

  query do

    alias Helix.Account.Model.Account
    alias Helix.Notification.Model.Notification

    @type methods :: :by_id | :by_account

    @spec by_id(Queryable.t, Notification.Account.id) ::
      Queryable.t
    def by_id(query \\ Notification.Account, id),
      do: where(query, [n], n.notification_id == ^id)

    @spec by_account(Queryable.t, Account.id) ::
      Queryable.t
    def by_account(query \\ Notification.Account, account_id),
      do: where(query, [n], n.account_id == ^account_id)
  end

  order do

    @type methods :: :by_newest

    @spec by_newest(Queryable.t) ::
      Queryable.t
    def by_newest(query),
      do: order_by(query, [n], desc: n.creation_time)
  end
end
