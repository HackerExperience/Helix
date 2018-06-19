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

  # TODO: Rename this method
  @spec get_notification_data(Event.t) ::
    {Notification.class, Notification.code}
  def get_notification_data(event)

  @spec whom_to_notify(Event.t) ::
    whom_to_notify
  def whom_to_notify(event)

  @spec extra_params(Event.t) ::
    map
  def extra_params(event)
end
