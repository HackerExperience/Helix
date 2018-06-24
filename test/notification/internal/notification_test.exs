defmodule Helix.Test.Notification.Internal.Notification do

  use Helix.Test.Case.Integration

  alias Helix.Notification.Internal.Notification, as: NotificationInternal
  alias Helix.Notification.Model.Notification

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Notification.Setup, as: NotificationSetup

  describe "add_notification/5" do
    test "adds notification when everything is valid" do
      {class, code} = NotificationSetup.random_code()
      {data, extra} = NotificationSetup.generate_data(class, code)
      id_map = NotificationSetup.generate_id_map(class)

      assert {:ok, notification} =
        NotificationInternal.add_notification(class, code, data, id_map, extra)

      assert notification.data == data
      assert notification.code == code
      assert Notification.get_class(notification) == class
      assert notification.account_id == id_map.account_id
      refute notification.is_read
    end

    test "fails miserably when code is invalid" do
      {class, code} = NotificationSetup.random_code()
      {data, extra} = NotificationSetup.generate_data(class, code)
      id_map = NotificationSetup.generate_id_map(class)

      bad_code = :not_a_valid_code

      assert {:error, changeset} =
        NotificationInternal.add_notification(
          class, bad_code, data, id_map, extra
        )

      refute changeset.valid?
      assert :code in Keyword.keys(changeset.errors)
    end
  end

  describe "mark_as_read/1" do
    test "marks a single notification as read" do
      notification = NotificationSetup.notification!()

      # Newly created notification is unread
      refute notification.is_read

      # We request that it is marked as read
      assert {:ok, newtification} =
        NotificationInternal.mark_as_read(notification)

      # Aaand it is
      assert newtification.is_read

      # Including on the DB
      assert newtification ==
        NotificationInternal.fetch(notification.notification_id)
    end
  end

  describe "mark_as_read/2" do
    test "marks all existing entries as read" do
      class = :account
      account_id = AccountHelper.id()

      # Creates three notifications within the same class, one of which is
      # already read
      notification1 =
        NotificationSetup.notification!(account_id: account_id, class: class)
      notification2 =
        NotificationSetup.notification!(account_id: account_id, is_read: true)
      notification3 =
        NotificationSetup.notification!(account_id: account_id, class: class)

      refute notification1.is_read
      assert notification2.is_read
      refute notification3.is_read

      # Mark notifications as read
      NotificationInternal.mark_as_read(class, account_id)

      # Retrieve again all three notifications
      [new_notif1, new_notif2, new_notif3] =
        NotificationInternal.get_by_account(class, account_id)

      # Read
      assert new_notif1.notification_id == notification1.notification_id
      assert new_notif1.is_read

      # Read (already was though)
      assert new_notif2.notification_id == notification2.notification_id
      assert new_notif2.is_read

      # Read
      assert new_notif3.notification_id == notification3.notification_id
      assert new_notif3.is_read
    end
  end
end
