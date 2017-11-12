defmodule Helix.Account.Websocket.Channel.Account.Topics.BrowseTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "bootstrap" do
    test "returns expected result" do
      {socket, _} = ChannelSetup.join_account()

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :ok, response, timeout()

      assert response.data.account
      assert response.data.servers
      assert response.data.storyline
    end
  end
end
