defmodule Helix.Notification.Query.Notification do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Notification.Internal.Notification, as: NotificationInternal
  alias Helix.Notification.Model.Notification

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

  def get_by_account(class, entity_id = %Entity.ID{}),
    do: get_by_account(class, Account.ID.cast!(to_string(entity_id)))
  def get_by_account(class, account_id = %Account.ID{}),
    do: NotificationInternal.get_by_account(class, account_id)
end

# defmodule Helix.Notification.Query.Notification.Account do

#   def get_by_account_id(account_id) do
#     account_id
#     |> NotificationInternal.account_get_by_account()
#   end

# end
