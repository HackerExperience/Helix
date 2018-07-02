defmodule Helix.Notification.Public.Notification do

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Notification.Action.Notification, as: NotificationAction
  alias Helix.Notification.Model.Notification

  @spec mark_as_read(Notification.t) ::
    term
  @doc """
  Marks the given `notification` as read.

  Emits: `NotificationReadEvent`
  """
  def mark_as_read(notification = %_{notification_id: _}) do
    with {:ok, _, events} <- NotificationAction.mark_as_read(notification) do
      Event.emit(events)
    end
  end

  @spec mark_as_read(Notification.class, Account.id) ::
    term
  @doc """
  Marks as read all notifications of given `class` and belonging to `account_id`

  Emits: `NotificationReadEvent`
  """
  def mark_as_read(class, account_id = %Account.ID{}) do
    with {:ok, events} <- NotificationAction.mark_as_read(class, account_id) do
      Event.emit(events)
    end
  end
end
