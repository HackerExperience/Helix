defmodule Helix.Notification.Public.Index.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Notification.Model.Code, as: NotificationCode
  alias Helix.Notification.Public.Index.Server, as: ServerNotificationIndex

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Notification.Setup, as: NotificationSetup

  describe "index/1" do
    test "returns all notifications from server" do
      account_id = AccountHelper.id()
      server_id = ServerHelper.id()

      id_map = %{account_id: account_id, server_id: server_id}

      n1 = NotificationSetup.notification!(id_map: id_map, class: :server)
      n2 = NotificationSetup.notification!(id_map: id_map, class: :server)

      # Index returns all `:server` notifications
      assert [n2, n1] == ServerNotificationIndex.index(server_id, account_id)
    end
  end

  describe "render_index/1" do
    test "returns valid, JSON-friendly data" do
      account_id = AccountHelper.id()
      server_id = ServerHelper.id()

      id_map = %{account_id: account_id, server_id: server_id}

      n1 = NotificationSetup.notification!(id_map: id_map, class: :server)
      _n2 = NotificationSetup.notification!(id_map: id_map, class: :account)
      n3 =
        NotificationSetup.notification!(
          id_map: id_map, class: :server, is_read: true
        )

      rendered_index =
        server_id
        |> ServerNotificationIndex.index(account_id)
        |> ServerNotificationIndex.render_index()

      assert [rendered_n3, rendered_n1] = rendered_index

      assert rendered_n1.notification_id == to_string(n1.notification_id)
      assert rendered_n1.code == to_string(n1.code)
      refute rendered_n1.is_read
      assert rendered_n1.data ==
        NotificationCode.render_data(:server, n1.code, n1.data)
      assert is_float(rendered_n1.creation_time)

      assert rendered_n3.notification_id == to_string(n3.notification_id)
      assert rendered_n3.code == to_string(n3.code)
      assert rendered_n3.is_read
      assert rendered_n3.data ==
        NotificationCode.render_data(:server, n3.code, n3.data)
      assert is_float(rendered_n3.creation_time)
    end
  end
end
