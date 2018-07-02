defmodule Helix.Notification.Public.Index.Server do

  alias HELL.ClientUtils
  alias HELL.HETypes
  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Model.Code, as: NotificationCode
  alias Helix.Notification.Query.Notification, as: NotificationQuery

  @type index :: [Notification.t]

  @type rendered_index :: [rendered_notification]

  @typep rendered_notification ::
    %{
      notification_id: String.t,
      code: String.t,
      data: map,
      is_read: boolean,
      creation_time: HETypes.client_timestamp
    }

  @spec index(Server.id, Account.id) ::
    index
  def index(server_id = %Server.ID{}, account_id = %Account.ID{}) do
    NotificationQuery.custom(:by_account_and_server, {account_id, server_id})
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    Enum.map(index, fn notification ->
      data =
        NotificationCode.render_data(
          :server, notification.code, notification.data
        )

      %{
        notification_id: to_string(notification.notification_id),
        code: to_string(notification.code),
        data: data,
        is_read: notification.is_read,
        creation_time: ClientUtils.to_timestamp(notification.creation_time)
      }
    end)
  end
end
