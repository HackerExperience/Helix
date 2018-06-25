defmodule Helix.Account.Websocket.Channel.Account.Topics.NotificationTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Query.Notification, as: NotificationQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Notification.Helper, as: NotificationHelper
  alias Helix.Test.Notification.Setup, as: NotificationSetup

  describe "notification.read" do
    test "marks a specific notification as read" do
      {socket, %{account_id: account_id}} = ChannelSetup.join_account()

      n1 = NotificationSetup.notification!(account_id: account_id)

      refute n1.is_read

      params = %{
        "notification_id" => n1.notification_id |> to_string()
      }

      # Send `notification.read` request
      ref = push socket, "notification.read", params
      assert_reply ref, :ok, %{}, timeout(:fast)

      # Client receives `notification_read` event
      [notification_read_event] = wait_events [:notification_read]

      assert notification_read_event.data.read_type == :one
      assert notification_read_event.data.class == Notification.get_class(n1)
      assert notification_read_event.data.notification_id ==
        to_string(n1.notification_id)

      # Notification was actually marked as read
      notification = NotificationQuery.fetch(n1.notification_id)
      assert notification.is_read
    end

    test "marks all notifications from class as read" do
      {socket, %{account_id: account_id}} = ChannelSetup.join_account()
      class = NotificationHelper.random_class()

      n1 = NotificationSetup.notification!(account_id: account_id, class: class)
      n2 = NotificationSetup.notification!(account_id: account_id, class: class)
      n3 = NotificationSetup.notification!(account_id: account_id, class: class)

      refute n1.is_read
      refute n2.is_read
      refute n3.is_read

      params = %{
        "class" => class |> to_string()
      }

      # Send `notification.read` request
      ref = push socket, "notification.read", params
      assert_reply ref, :ok, %{}, timeout(:fast)

      # Client receives `notification_read` event
      [notification_read_event] = wait_events [:notification_read]

      assert notification_read_event.data.read_type == :all
      assert notification_read_event.data.class == class
      refute notification_read_event.data.notification_id

      # All underlying notifications were marked as read
      assert [new_n1, new_n2, new_n3] =
        NotificationQuery.get_by_account(class, account_id)

      assert new_n1.notification_id == n1.notification_id
      assert new_n1.is_read

      assert new_n2.notification_id == n2.notification_id
      assert new_n2.is_read

      assert new_n3.notification_id == n3.notification_id
      assert new_n3.is_read
    end

    test "fails to read notification from another user" do
      {socket, %{account_id: account_id}} = ChannelSetup.join_account()

      n1 = NotificationSetup.notification!()

      # Belongs to another user
      refute n1.account_id == account_id

      params = %{
        "notification_id" => n1.notification_id |> to_string()
      }

      # Send `notification.read` request
      ref = push socket, "notification.read", params
      assert_reply ref, :error, result, timeout(:fast)

      assert result.data.message == "notification_not_belongs"
    end
  end
end
