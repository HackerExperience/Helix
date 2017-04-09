defmodule Helix.Websocket.SocketTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.Session
  alias Helix.Websocket.Socket

  alias Helix.Account.Factory, as: AccountFactory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  test "socket is NOT connectable by anyone" do
    assert :error = connect(Socket, %{})
  end

  test "socket is connectable only with valid token" do
    account = AccountFactory.insert(:account)
    token = Session.generate_token(account)

    assert {:ok, _} = connect(Socket, %{"token" => token})
  end
end
