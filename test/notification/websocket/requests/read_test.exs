defmodule Helix.Notification.Websocket.Requests.ReadTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Notification.Websocket.Requests.Read, as: NotificationReadRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Notification.Helper, as: NotificationHelper

  @mock_socket ChannelSetup.mock_account_socket()

  describe "NotificationReadRequest.check_params/2" do
    test "rejects when both `class` and `notification_id` are specified" do
      notification_id = NotificationHelper.generate_id()

      params =
        %{
          "notification_id" => to_string(notification_id),
          "class" => "server"
        }

      request = NotificationReadRequest.new(params)

      assert {:error, %{message: reason}, _} =
        Requestable.check_params(request, @mock_socket)
      assert reason == "read_the_docs"
    end

    test "rejects when neither `class` and `notification_id` are specified" do
      params = %{"wat" => "taw"}

      request = NotificationReadRequest.new(params)

      assert {:error, %{message: reason}, _} =
        Requestable.check_params(request, @mock_socket)

      assert reason == "bad_request"
    end
  end
end
