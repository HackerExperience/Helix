defmodule Helix.Notification.Websocket.Requests.Read.AllTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Notification.Query.Notification, as: NotificationQuery
  alias Helix.Notification.Websocket.Requests.Read.All,
    as: NotificationReadAllRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Notification.Helper, as: NotificationHelper
  alias Helix.Test.Notification.Setup, as: NotificationSetup

  @mock_socket ChannelSetup.mock_account_socket()

  describe "NotificationReadAllRequest.check_params/2" do
    test "validates everything" do
      class = NotificationHelper.random_class()
      params =
        %{
          "class" => to_string(class)
        }

      request = NotificationReadAllRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      # Correctly validated underlying `class`
      assert request.params.class == class
    end

    test "rejects when `class` is invalid" do
      p0 = %{"class" => 1}
      p1 = %{"class" => "does_not_exist"}  # Atom won't be found

      r0 = NotificationReadAllRequest.new(p0)
      r1 = NotificationReadAllRequest.new(p1)

      assert {:error, reason0, _} = Requestable.check_params(r0, @mock_socket)
      assert {:error, reason1, _} = Requestable.check_params(r1, @mock_socket)

      assert reason0 == %{message: "bad_request"}
      assert reason1 == %{message: "bad_class"}
    end
  end

  describe "NotificationReadAllRequest.check_permissions/2" do
    test "accepts when class can be marked as read" do
      account_id = AccountHelper.id()
      socket =
        ChannelSetup.mock_account_socket(connect_opts: [account_id: account_id])

      params = %{class: NotificationHelper.random_class()}

      request = RequestHelper.mock_request(NotificationReadAllRequest, params)

      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.account_id == account_id
    end
  end

  describe "NotificationReadAllRequest.handle_request/2" do
    test "mark all notifications as read" do
      account_id = AccountHelper.id()
      class = :account

      n1 = NotificationSetup.notification!(account_id: account_id, class: class)
      n2 = NotificationSetup.notification!(account_id: account_id, class: class)

      # Currently unread
      refute n1.is_read
      refute n2.is_read

      socket =
        ChannelSetup.mock_account_socket(connect_opts: [account_id: account_id])

      params = %{class: class}
      meta = %{account_id: account_id}

      request =
        RequestHelper.mock_request(NotificationReadAllRequest, params, meta)

      assert {:ok, _} = Requestable.handle_request(request, socket)

      # Both notifications were marked as read
      assert [new_n2, new_n1] =
        NotificationQuery.get_by_account(class, account_id)

      assert new_n1.notification_id == n1.notification_id
      assert new_n1.is_read

      assert new_n2.notification_id == n2.notification_id
      assert new_n2.is_read
    end
  end
end
