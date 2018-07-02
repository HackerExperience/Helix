defmodule Helix.Notification.Public.Index.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Notification.Model.Code, as: NotificationCode
  alias Helix.Notification.Public.Index.Account, as: AccountNotificationIndex

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Notification.Setup, as: NotificationSetup

  describe "index/1" do
    test "returns all notifications from account" do
      account_id = AccountHelper.id()

      n1 =
        NotificationSetup.notification!(account_id: account_id, class: :account)
      _n2 =
        NotificationSetup.notification!(account_id: account_id, class: :server)
      n3 =
        NotificationSetup.notification!(account_id: account_id, class: :account)

      # Index returns all `:account` notifications
      assert [n3, n1] == AccountNotificationIndex.index(account_id)
    end
  end

  describe "render_index/1" do
    test "returns valid, JSON-friendly data" do
      account_id = AccountHelper.id()

      n1 =
        NotificationSetup.notification!(account_id: account_id, class: :account)
      _n2 =
        NotificationSetup.notification!(account_id: account_id, class: :server)
      n3 =
        NotificationSetup.notification!(
          account_id: account_id, class: :account, is_read: true
        )

      rendered_index =
        account_id
        |> AccountNotificationIndex.index()
        |> AccountNotificationIndex.render_index()

      assert [rendered_n3, rendered_n1] = rendered_index

      assert rendered_n1.notification_id == to_string(n1.notification_id)
      assert rendered_n1.code == to_string(n1.code)
      refute rendered_n1.is_read
      assert rendered_n1.data ==
        NotificationCode.render_data(:account, n1.code, n1.data)
      assert is_float(rendered_n1.creation_time)

      assert rendered_n3.notification_id == to_string(n3.notification_id)
      assert rendered_n3.code == to_string(n3.code)
      assert rendered_n3.is_read
      assert rendered_n3.data ==
        NotificationCode.render_data(:account, n3.code, n3.data)
      assert is_float(rendered_n3.creation_time)
    end
  end
end
