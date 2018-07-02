defmodule Helix.Notification.Public.Index.Account do

  alias HELL.ClientUtils
  alias HELL.HETypes
  alias Helix.Account.Model.Account
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

  @spec index(Account.id) ::
    index
  def index(account_id = %Account.ID{}),
    do: NotificationQuery.get_by_account(:account, account_id)

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    Enum.map(index, fn notification ->
      data =
        NotificationCode.render_data(
          :account, notification.code, notification.data
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
