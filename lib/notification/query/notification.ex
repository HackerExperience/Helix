defmodule Helix.Notification.Query.Notification do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Notification.Internal.Notification, as: NotificationInternal
  alias Helix.Notification.Model.Notification

  @spec fetch(Notification.id | tuple) ::
    Notification.t
    | nil
  def fetch(notification_id) when is_tuple(notification_id) do
    notification_id
    |> Notification.cast_id()
    |> fetch()
  end

  def fetch(notification_id) do
    notification_id
    |> Notification.get_class()
    |> NotificationInternal.fetch(notification_id)
  end

  @spec get_by_account(Notification.class, Entity.id | Account.id) ::
    [Notification.t]
  @doc """
  Returns all notifications that belong to `class` and to the given account.
  """
  def get_by_account(class, entity_id = %Entity.ID{}),
    do: get_by_account(class, Account.ID.cast!(to_string(entity_id)))
  def get_by_account(class, account_id = %Account.ID{}),
    do: NotificationInternal.get_by_account(class, account_id)
end
