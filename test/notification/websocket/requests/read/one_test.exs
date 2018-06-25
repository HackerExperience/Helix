defmodule Helix.Notification.Websocket.Requests.Read.OneTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Notification.Query.Notification, as: NotificationQuery
  alias Helix.Notification.Websocket.Requests.Read.One,
    as: NotificationReadOneRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Notification.Helper, as: NotificationHelper
  alias Helix.Test.Notification.Setup, as: NotificationSetup

  @mock_socket ChannelSetup.mock_account_socket()

  describe "NotificationReadOneRequest.check_params/2" do
    test "validates everything" do
      notification_id = NotificationHelper.generate_id()

      params =
        %{
          "notification_id" => to_string(notification_id)
        }

      request = NotificationReadOneRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      # Correctly validated underlying `notification_id`
      assert request.params.notification_id == notification_id
    end

    test "rejects when `notification_id` is invalid" do
      p0 = %{"notification_id" => "abc"}
      p1 = %{"notification_id" => ServerHelper.id() |> to_string()}
      p2 = %{"notification_id" => 123}

      r0 = NotificationReadOneRequest.new(p0)
      r1 = NotificationReadOneRequest.new(p1)
      r2 = NotificationReadOneRequest.new(p2)

      assert {:error, reason0, _} = Requestable.check_params(r0, @mock_socket)
      assert {:error, reason1, _} = Requestable.check_params(r1, @mock_socket)
      assert {:error, reason2, _} = Requestable.check_params(r2, @mock_socket)

      assert reason0 == %{message: "bad_request"}
      assert reason1 == reason0
      assert reason2 == reason1
    end
  end

  describe "NotificationReadOneRequest.check_permissions/2" do
    test "accepts when notification can be read" do
      # Create the underlying notification
      notification = NotificationSetup.notification!()

      # Mock a socket that belongs to the owner of the notification
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [account_id: notification.account_id]
        )

      params = %{notification_id: notification.notification_id}

      request = RequestHelper.mock_request(NotificationReadOneRequest, params)

      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.account_id == notification.account_id
      assert request.meta.notification == notification
    end

    test "rejects when notification can't be read" do
      # Create the underlying notification
      notification = NotificationSetup.notification!()

      # Mock a socket that DOES NOT belong to the owner of the notification
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [account_id: AccountHelper.id()]
        )

      params = %{notification_id: notification.notification_id}

      request = RequestHelper.mock_request(NotificationReadOneRequest, params)

      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

      assert reason == "notification_not_belongs"
    end
  end

  describe "NotificationReadOneRequest.handle_request/2" do
    test "marks notification as read" do
      # Create the underlying notification
      notification = NotificationSetup.notification!()

      # Mock a socket that belongs to the owner of the notification
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [account_id: notification.account_id]
        )

      params = %{notification_id: notification.notification_id}
      meta = %{notification: notification}

      request =
        RequestHelper.mock_request(NotificationReadOneRequest, params, meta)

      assert {:ok, _} = Requestable.handle_request(request, socket)

      # Request is now marked as read
      new_request = NotificationQuery.fetch(notification.notification_id)
      assert new_request.is_read
    end
  end
end
