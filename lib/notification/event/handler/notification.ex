defmodule Helix.Notification.Event.Handler.Notification do

  import HELL.Macros

  alias Helix.Event
  alias Helix.Event.Notificable
  alias Helix.Notification.Action.Notification, as: NotificationAction
  alias Helix.Notification.Model.Code, as: NotificationCode
  alias Helix.Notification.Model.Notification

  def notification_handler(event) do
    if Notificable.impl_for(event) do
      {class, code} = Notificable.get_notification_data(event)
      extra_params = Notificable.extra_params(event)
      whom_to_notify = Notificable.whom_to_notify(event)
      data = NotificationCode.generate_data(class, code, event)

      class
      |> get_target_ids(whom_to_notify)
      |> Enum.map(fn id_map ->
        with \
          {:ok, _, event} <-
            NotificationAction.add_notification(
              class, code, data, id_map, extra_params
            )
        do
          Event.emit(event)
        end
      end)
    end
  end

  @spec get_target_ids(Notification.class, Notificable.whom_to_notify) ::
    [Notification.id_map]
  docp """
  Returns the list of players that shall receive the notification.

  This list was passed through `Notification.get_id_map/2` and it contains all
  id information the notification needs to be stored correctly.
  """
  defp get_target_ids(:account, account_id),
    do: [Notification.get_id_map(:account, account_id)]
  defp get_target_ids(:server, %{account_id: account_id, server_id: server_id}),
    do: [Notification.get_id_map(:server, {server_id, account_id})]

  # Below snippet is an example on how to extend the `get_notification_list/2`
  # defp get_notification_list(:server, server_id = %Server.ID{}) do
  #   server_id
  #   |> ServerQuery.get_all_accounts_logged_in_server()
  #   |> Enum.map(fn account_id ->
  #     Notification.get_id_map(
  #       class, %{server_id: server_id, account_id: account_id}
  #     )
  #   end)
  # end

end
