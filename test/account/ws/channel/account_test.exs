defmodule Helix.Account.WS.Channel.AccountTest do

  use ExUnit.Case, async: true

  alias Helix.Router.Socket.Player, as: Socket
  alias Helix.Account.Controller.Session
  alias Helix.Account.WS.Channel.Account, as: Channel

  alias Helix.Account.Factory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  setup do
    account = Factory.insert(:account)
    {:ok, jwt, _} = Session.create(account)
    {:ok, socket} = connect(Socket, %{token: jwt})
    {:ok, _, socket} = join(socket, "account:" <> account.account_id)

    {:ok, account: account, socket: socket}
  end

  test "an user can't join another user's notification channel", context do
    another_account = Factory.insert(:account)
    id = another_account.account_id
    assert {:error, _} = join(context.socket, "account:" <> id)
  end

  describe "notification/2" do
    test "pushes message to all clients", context do
      notification = %{warning: "all your base are belong to us!"}
      Channel.notify(context.account.account_id, notification)

      assert_push "notification", %{warning: "all your base are belong to us!"}
    end
  end
end
