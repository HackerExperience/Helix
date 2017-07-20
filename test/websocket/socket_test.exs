defmodule Helix.Websocket.SocketTest do

  use Helix.Test.IntegrationCase

  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Websocket.Socket

  alias Helix.Account.Factory, as: AccountFactory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  test "socket is NOT connectable by anyone" do
    assert :error = connect(Socket, %{})
  end

  test "socket is connectable only with valid token" do
    account = AccountFactory.insert(:account)
    token = SessionAction.generate_token(account)

    assert {:ok, _} = connect(Socket, %{"token" => token})
  end
end
