defmodule Helix.Notification.Event.Notification do

  import Helix.Event

  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Model.Code, as: NotificationCode

  event Added do
    @moduledoc """
    `NotificationAddedEvent` is fired right after a notification has been added.

    It will then publish the event to the player(s), based on the notification
    class and content.
    """

    @type t ::
      %__MODULE__{
        notification: Notification.t
      }

    event_struct [:notification]

    def new(notification = %_{code: _, data: _}) do
      %__MODULE__{
        notification: notification
      }
    end

    publish do

      @event :notification_added

      def generate_payload(event, _socket) do
        class = Notification.get_class(event.notification)
        code = event.notification.code
        notification_data = event.notification.data
        extra_data = get_extra_data(event.notification)

        data =
          %{
            notification_id: to_string(event.notification.notification_id),
            class: class,
            code: code,
            data: NotificationCode.render_data(class, code, notification_data)
          }
          |> Map.merge(extra_data)

        {:ok, data}
      end

      # Notification.Account are fired directly to the underlying account
      def whom_to_publish(
        %{notification: %Notification.Account{account_id: account_id}}
      ) do
        %{account: account_id}
      end

      # Notification.Server are fired to the specified `account_id`
      def whom_to_publish(
        %{notification: %Notification.Server{account_id: account_id}}
      ) do
        %{account: account_id}
      end

      defp get_extra_data(%Notification.Account{}),
        do: %{}
      defp get_extra_data(%Notification.Server{network_id: network_id, ip: ip}),
        do: %{network_id: to_string(network_id), ip: ip}
    end
  end
end
