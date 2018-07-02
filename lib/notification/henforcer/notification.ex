defmodule Helix.Notification.Henforcer.Notification do

  import Helix.Henforcer

  alias Helix.Account.Model.Account
  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Query.Notification, as: NotificationQuery

  @type notification_exists_relay :: %{notification: Notification.t}
  @type notification_exists_partial_relay :: %{}
  @type notification_exists_error ::
    {false, {:notification, :not_found}, notification_exists_partial_relay}

  @spec notification_exists?(Notification.id) ::
    {true, notification_exists_relay}
    | notification_exists_error
  @doc """
  Henforces that the given `notification_id` maps to a real notification.
  """
  def notification_exists?(notification_id) do
    with notification = %_{} <- NotificationQuery.fetch(notification_id) do
      reply_ok(relay(%{notification: notification}))
    else
      _ ->
        reply_error({:notification, :not_found})
    end
  end

  @type owns_notification_relay :: %{}
  @type owns_notification_relay_partial :: %{}
  @type owns_notification_error ::
    {false, {:notification, :not_belongs}, owns_notification_relay_partial}

  @spec owns_notification?(Account.id, Notification.t) ::
    {true, owns_notification_relay}
    | owns_notification_error
  @doc """
  Henforces that the given notification belongs (is owned by) the given account.
  """
  def owns_notification?(account_id, %_{account_id: account_id}),
    do: reply_ok()
  def owns_notification?(_, _),
    do: reply_error({:notification, :not_belongs})

  @type can_read_relay :: %{notification: Notification.t}
  @type can_read_error ::
    notification_exists_error
    | owns_notification_error

  @spec can_read?(Notification.id, Account.id) ::
    {true, can_read_relay}
    | can_read_error
  @doc """
  Henforces that the given notification can be read by the given account.

  The notification must exist, and a player must not read another player's
  notification.
  """
  def can_read?(notification_id, account_id = %Account.ID{}) do
    with \
      {true, r1} <- notification_exists?(notification_id),
      notification = r1.notification,
      {true, _} <- owns_notification?(account_id, notification)
    do
      reply_ok(r1)
    end
  end
end
