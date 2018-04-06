defmodule Helix.Account.Websocket.Channel.Account.Topics.ClientTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "client.action" do
    test "broadcasts that `action` has been performed" do
      {socket, _} = ChannelSetup.join_account(socket_opts: [client: :web1])

      params =
        %{
          "action" => "tutorial_accessed_task_manager"
        }

      ref = push socket, "client.action", params
      assert_reply ref, :ok, response

      assert Enum.empty?(response.data)
    end

    test "returns error when `action` does not exist" do
      {socket, _} = ChannelSetup.join_account(socket_opts: [client: :web1])

      params =
        %{
          "action" => "invalid_client_action"
        }

      ref = push socket, "client.action", params
      assert_reply ref, :error, response

      assert response.data.message == "bad_action"
    end
  end
end
