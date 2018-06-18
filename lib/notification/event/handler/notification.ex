defmodule Helix.Notification.Event.Handler.Notification do

  import HELL.Macros

  alias HELL.Utils
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
      |> get_notification_list(whom_to_notify)
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

  docp """
  Returns the list of players that shall receive the notification.
  """
  defp get_notification_list(class, whom_to_notify) do
    class
    |> Notification.get_notification_map(whom_to_notify)
    |> Utils.ensure_list()
  end
end
