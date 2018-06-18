defmodule Helix.Notification.Action.Notification do

  alias Helix.Notification.Internal.Notification, as: NotificationInternal
  alias Helix.Notification.Model.Code, as: NotificationCode

  alias Helix.Notification.Event.Notification.Added, as: NotificationAddedEvent

  def add_notification(class, code, data, ids, extra) do
    case NotificationInternal.add_notification(class, code, data, ids, extra) do
      {:ok, notification} ->
        {:ok, notification, [NotificationAddedEvent.new(notification)]}

      error = {:error, _} ->
        error
    end
  end
end
