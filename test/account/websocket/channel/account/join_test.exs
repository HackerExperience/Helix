defmodule Helix.Account.Websocket.Channel.Account.JoinTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Account.Setup, as: AccountSetup

  test "user can join his own channel" do
    {socket, %{account: player}} = ChannelSetup.create_socket()

    topic = "account:" <> to_string(player.account_id)

    assert {:ok, bootstrap, new_socket} = join(socket, topic)
    assert new_socket.assigns.account_id == player.account_id

    # Returns the account bootstrap as reply
    assert bootstrap.data.servers
    assert bootstrap.data.account

    # Also returns client-specific stuff
    assert new_socket.assigns.client
  end

  test "an user can't join another user's channel" do
    {socket, _} = ChannelSetup.create_socket()

    {another_player, _} = AccountSetup.account()

    topic = "account:" <> to_string(another_player.account_id)

    assert {:error, reason} = join(socket, topic)
    assert reason.data == "access_denied"
  end
end
