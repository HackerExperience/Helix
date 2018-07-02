import Helix.Websocket.Request

request Helix.Notification.Websocket.Requests.Read.One do
  @moduledoc """
  `NotificationReadOneRequest` is called when the player wants to mark a custom
  notification as read.
  """

  import HELL.Macros

  alias Helix.Account.Model.Account
  alias Helix.Notification.Henforcer.Notification, as: NotificationHenforcer
  alias Helix.Notification.Public.Notification, as: NotificationPublic

  def check_params(request, _socket) do
    with \
      {:ok, notification_id} <-
        validate_input(request.unsafe["notification_id"], :notification_id),
      true <- not Map.has_key?(request.unsafe, "class") || :read_the_docs
    do
      params = %{notification_id: notification_id}

      update_params(request, params, reply: true)
    else
      error = :read_the_docs ->
        reply_error(request, error)

      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    entity_id = socket.assigns.entity_id
    account_id = Account.ID.cast!(to_string(entity_id))
    notification_id = request.params.notification_id

    case NotificationHenforcer.can_read?(notification_id, account_id) do
      {true, relay} ->
        meta =
          %{
            account_id: account_id,
            notification: relay.notification
          }

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, _socket) do
    notification = request.meta.notification

    hespawn fn ->
      NotificationPublic.mark_as_read(notification)
    end

    reply_ok(request)
  end

  render_empty()
end
