defmodule Helix.Notification.Action.Notification do

  alias Helix.Notification.Internal.Notification, as: NotificationInternal
  alias Helix.Notification.Model.Notification

  alias Helix.Notification.Event.Notification.Added, as: NotificationAddedEvent

  @spec add_notification(
    Notification.class,
    Notification.code,
    Notification.data,
    Notification.id_map,
    map
  ) ::
    {:ok, Notification.t, [NotificationAddedEvent.t]}
    | {:error, Notification.changeset}
  @doc """
  Inserts the given notification into the database.

  The given params contain all information required to correctly store the
  notification.
  """
  def add_notification(class, code, data, ids, extra) do
    case NotificationInternal.add_notification(class, code, data, ids, extra) do
      {:ok, notification} ->
        {:ok, notification, [NotificationAddedEvent.new(notification)]}

      error = {:error, _} ->
        error
    end
  end
end
