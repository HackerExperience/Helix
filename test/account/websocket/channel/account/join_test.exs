defmodule Helix.Account.Websocket.Channel.Account.JoinTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Account.Setup, as: AccountSetup

  test "user can join his own notification channel" do
    {socket, %{account: player}} = ChannelSetup.create_socket()

    topic = "account:" <> to_string(player.account_id)

    assert {:ok, _, new_socket} = join(socket, topic)
    assert new_socket.assigns.account == player
  end

  test "an user can't join another user's notification channel" do
    {socket, _} = ChannelSetup.create_socket()

    {another_player, _} = AccountSetup.account()

    topic = "account:" <> to_string(another_player.account_id)

    assert {:error, reason} = join(socket, topic)
    assert reason.data == "access_denied"
  end
end
