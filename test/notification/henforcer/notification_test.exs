defmodule Helix.Notification.Henforcer.NotificationTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Notification.Henforcer.Notification, as: NotificationHenforcer

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Notification.Helper, as: NotificationHelper
  alias Helix.Test.Notification.Setup, as: NotificationSetup

  describe "notification_exists?/1" do
    test "accepts when notification exists" do
      {notification, _} = NotificationSetup.notification()

      assert {true, relay} =
        NotificationHenforcer.notification_exists?(notification.notification_id)

      assert relay.notification == notification

      assert_relay relay, [:notification]
    end

    test "rejects when notification does not exist" do
      notification_id = NotificationHelper.generate_id()

      assert {false, reason, _} =
        NotificationHenforcer.notification_exists?(notification_id)

      assert reason == {:notification, :not_found}
    end
  end

  describe "owns_notification?/2" do
    test "accepts when account owns the notification" do
      {notification, %{account_id: account_id}} =
        NotificationSetup.notification()

      assert {true, relay} =
        NotificationHenforcer.owns_notification?(account_id, notification)

      assert relay == %{}
    end

    test "rejects when account does not own the notification" do
      {notification, _} = NotificationSetup.notification()
      account_id = AccountHelper.id()

      assert {false, reason, _} =
        NotificationHenforcer.owns_notification?(account_id, notification)

      assert reason == {:notification, :not_belongs}
    end
  end

  describe "can_read?/2" do
    test "accepts when notification can be read by the user" do
      {notification, %{account_id: account_id}} =
        NotificationSetup.notification()

      assert {true, relay} =
        NotificationHenforcer.can_read?(
          notification.notification_id, account_id
        )

      assert relay.notification == notification
      assert_relay relay, [:notification]
    end

    test "rejects when notification does not belong to user" do
      {notification, _} = NotificationSetup.notification()
      account_id = AccountHelper.id()

      assert {false, reason, _} =
        NotificationHenforcer.can_read?(
          notification.notification_id, account_id
        )

      assert reason == {:notification, :not_belongs}
    end
  end
end
