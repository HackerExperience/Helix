defmodule Helix.Account.Websocket.Channel.AccountTest do

  use Helix.Test.IntegrationCase

  alias Helix.Websocket.Socket
  alias Helix.Account.Service.API.Session
  alias Helix.Account.Websocket.Channel.Account, as: Channel

  alias Helix.Account.Factory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  setup do
    account = Factory.insert(:account)
    token = Session.generate_token(account)
    {:ok, socket} = connect(Socket, %{token: token})
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
