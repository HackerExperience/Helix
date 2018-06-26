defmodule Helix.Notification.Event.Handler.NotificationTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID
  import Helix.Test.Channel.Macros

  alias Helix.Notification.Query.Notification, as: NotificationQuery

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Notification.Helper, as: NotificationHelper

  # Dear reader,
  # This broad test is meant to make sure notifications work right. We've picked
  # a specific event (ServerPasswordAcquiredEvent) to be used as test subject
  # here. By no means is this test supposed to cover each event that implements
  # the Notificable protocol. For this purpose you should check each event's
  # tests. Similar to PublicationHandlerTest. Peace.
  describe "notification_handler/1" do
    test "creates a new notification entry" do
      entity = EntitySetup.entity!()
      {server, _} = ServerSetup.server()

      event = EventSetup.Server.password_acquired(entity.entity_id, server)

      EventHelper.emit(event)

      assert [notification] =
        NotificationQuery.get_by_account(:account, entity.entity_id)

      # Notification ID has the correct Account class suffix
      expected_suffix = NotificationHelper.expected_suffix(:account)
      suffix = NotificationHelper.get_suffix(notification.notification_id)

      assert expected_suffix == suffix

      # Notification code is OK
      assert notification.code == :server_password_acquired

      # Notification payload is correct and well-formatted
      assert notification.data.network_id == event.network_id
      assert notification.data.ip == event.server_ip
      assert notification.data.password == event.password

      # Other stuff
      refute notification.is_read
      assert notification.creation_time

      # No server-specific keys
      refute Map.has_key?(notification, :nip)
    end

    test "publishes NotificationAddedEvent to the client" do
      event = EventSetup.Software.file_downloaded()
      account = AccountHelper.fetch_account_from_entity(event.entity_id)

      {socket, _} =
        ChannelSetup.create_socket(
          entity_id: event.entity_id, with_server: false
        )

      # Join AccountChannel so we can listen to publications sent to it
      ChannelSetup.join_account(socket: socket, account_id: account.account_id)

      EventHelper.emit(event)

      # Notification was added
      assert [notification] =
        NotificationQuery.get_by_account(:server, event.entity_id)

      # Correct suffix was used
      expected_suffix = NotificationHelper.expected_suffix(:server)
      suffix = NotificationHelper.get_suffix(notification.notification_id)

      assert expected_suffix == suffix

      assert notification.code == :file_downloaded

      # Client received the `notification_added_event` publication
      [notification_added_event] = wait_events [:notification_added]

      assert_id notification.notification_id,
        notification_added_event.data.notification_id

      refute Map.has_key?(notification_added_event, :server_id)

      # Added file information on the notification data
      assert notification_added_event.data.data.name == event.file.name
      assert notification_added_event.data.data.id ==
        to_string(event.file.file_id)
    end
  end
end
