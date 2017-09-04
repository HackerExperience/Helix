defmodule Helix.Account.Websocket.Channel.Account.Requests.BrowseTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "bootstrap" do
    test "returns expected result" do
      {socket, _} = ChannelSetup.join_account()

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :ok, response

      assert response.data.account
      assert response.data.servers
    end
  end

  @tag :pending
  test "removes duplicates"
end
