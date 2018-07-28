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

      alias HELL.Utils
      alias Helix.Account.Model.Account
      alias Helix.Cache.Query.Cache, as: CacheQuery
      alias Helix.Entity.Query.Entity, as: EntityQuery

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
      defp get_extra_data(notification = %Notification.Server{}) do
        # We have to publish the server information to the Client, so it knows
        # where to display the notification.
        # If the server belongs to the given account, we publish the raw
        # `server_id`. Otherwise, we publish the server's `network_id` and `ip`.
        entity = EntityQuery.fetch_by_server(notification.server_id)
        account_id = Account.cast_from_entity(entity.entity_id)

        if account_id == notification.account_id do
          %{server_id: notification.server_id |> to_string()}
        else
          notification.server_id
          |> CacheQuery.from_server_get_nips!()
          |> List.first()
          |> Utils.stringify_map()
        end
      end
    end
  end

  event Read do
    @moduledoc """
    `NotificationReadEvent` is fired right after a notification has been marked
    as read.

    It may represent two cases: either a specific notification was marked as
    read, in which case we call it `read_type = :one`, or all notifications from
    a specific class were marked as read, in which case we name it
    `read_type = all`.

    The contents of the event struct vary according to which `read_type` we
    have, so read the types below and beware!
    """

    alias Helix.Account.Model.Account
    alias Helix.Notification.Model.Notification

    @type t_one ::
      %__MODULE__{
        notification_id: Notification.id,
        class: Notification.class,
        account_id: Account.id,
        read_type: :one
      }

    @type t_all ::
      %__MODULE__{
        notification_id: nil,
        class: Notification.class,
        account_id: Account.id,
        read_type: :all
      }

    event_struct [:notification_id, :class, :read_type, :account_id]

    @spec new(Notification.t) ::
      t_one
    def new(notification = %_{notification_id: _}) do
      %__MODULE__{
        notification_id: notification.notification_id,
        class: Notification.get_class(notification),
        read_type: :one,
        account_id: notification.account_id
      }
    end

    @spec new(Notification.class, Account.id) ::
      t_all
    def new(class, account_id = %Account.ID{}) when is_atom(class) do
      %__MODULE__{
        notification_id: nil,
        class: class,
        read_type: :all,
        account_id: account_id
      }
    end

    publish do

      @event :notification_read

      def generate_payload(event, _socket) do
        notification_id =
          event.notification_id
          && to_string(event.notification_id)
          || nil

        data =
          %{
            notification_id: notification_id,
            class: event.class,
            read_type: event.read_type
          }

        {:ok, data}
      end

      def whom_to_publish(event),
        do: %{account: event.account_id}
    end
  end
end
