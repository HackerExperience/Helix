defmodule Helix.Notification.Action.Notification do

  alias Helix.Account.Model.Account
  alias Helix.Notification.Internal.Notification, as: NotificationInternal
  alias Helix.Notification.Model.Notification

  alias Helix.Notification.Event.Notification.Added, as: NotificationAddedEvent
  alias Helix.Notification.Event.Notification.Read, as: NotificationReadEvent

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

  @spec mark_as_read(Notification.t) ::
    {:ok, Notification.t, [NotificationReadEvent.t_one]}
    | {:error, :internal}
  def mark_as_read(notification = %_{}) do
    case NotificationInternal.mark_as_read(notification) do
      {:ok, notification} ->
        {:ok, notification, [NotificationReadEvent.new(notification)]}

      {:error, _changeset} ->
        {:error, :internal}
    end
  end

  @spec mark_as_read(Notification.class, Account.id) ::
    {:ok, [NotificationReadEvent.t_all]}
  def mark_as_read(class, account_id = %Account.ID{}) do
    with :ok <- NotificationInternal.mark_as_read(class, account_id) do
      {:ok, [NotificationReadEvent.new(class, account_id)]}
    end
  end
end
