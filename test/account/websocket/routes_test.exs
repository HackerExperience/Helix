defmodule Helix.Account.Websocket.RoutesTest do

  use Helix.Test.IntegrationCase

  alias Helix.Websocket.Socket
  alias Helix.Account.Service.API.Session

  alias Helix.Account.Factory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  setup do
    account = Factory.insert(:account)
    token = Session.generate_token(account)
    {:ok, socket} = connect(Socket, %{token: token})
    {:ok, _, socket} = join(socket, "requests")

    {:ok, account: account, token: token, socket: socket}
  end

  test "logout closes socket", context do
    push(context.socket, "account.logout")

    :timer.sleep(100)

    refute Process.alive? context.socket.channel_pid
    # The token has been invalidated so we should not be able to use it again
    assert :error == connect(Socket, %{token: context.token})
  end
end
