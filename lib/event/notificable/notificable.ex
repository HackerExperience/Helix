defprotocol Helix.Event.Notificable do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Notification.Model.Notification
  alias Helix.Server.Model.Server
  alias Helix.Event

  @type whom_to_notify ::
    Account.id
    | Entity.id
    | %{account_id: Account.id, server_id: Server.id}
    | %{account_id: Entity.id, server_id: Server.id}
    | Server.id

  @spec get_notification_info(Event.t) ::
    {Notification.class, Notification.code}
  @doc """
  Returns a `{class, code}` tuple that identifies the notification.
  """
  def get_notification_info(event)

  @spec whom_to_notify(Event.t) ::
    whom_to_notify
  @doc """
  Returns a value that tells the NotificationHandler who should receive the
  notifications.
  """
  def whom_to_notify(event)

  @spec extra_params(Event.t) ::
    map
  @doc """
  Map with arbitrary values that will be added into the Notification and saved
  on the database.
  """
  def extra_params(event)
end
