defmodule Helix.Account.Websocket.Channel.Account.Requests.LogoutTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Websocket

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  @endpoint Helix.Endpoint

  describe "bootstrap" do
    test "returns expected result" do
      {socket, %{token: token}} = ChannelSetup.join_account()

      # Request logout
      push socket, "account.logout", %{}

      # Wait process teardown. Required
      :timer.sleep(50)

      # Channel no longer exists
      refute Process.alive? socket.channel_pid

      # The token has been invalidated so we should not be able to use it again
      assert :error == connect(Websocket, %{token: token})
    end
  end
end
