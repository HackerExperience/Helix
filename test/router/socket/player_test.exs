defmodule Helix.Router.Socket.PlayerTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.Session
  alias Helix.Router.Socket.Player, as: Socket

  alias Helix.Account.Factory, as: AccountFactory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  test "socket is NOT connectable by anyone" do
    assert :error = connect(Socket, %{})
  end

  test "socket is connectable only with valid JWT token" do
    account = AccountFactory.insert(:account)
    token = Session.generate_token(account)

    assert {:ok, _} = connect(Socket, %{"token" => token})
  end

  test "identifies users within different connections" do
    account0 = AccountFactory.insert(:account)
    account1 = AccountFactory.insert(:account)

    token = Session.generate_token(account0)
    {:ok, socket0} = connect(Socket, %{"token" => token})
    {:ok, socket1} = connect(Socket, %{"token" => token})

    token = Session.generate_token(account1)
    {:ok, socket2} = connect(Socket, %{"token" => token})

    id0 = Socket.id(socket0)
    id1 = Socket.id(socket1)
    id2 = Socket.id(socket2)

    # Both socket0 and socket1 use a JWT that gives access to the same account
    # so both sockets belong to the same player (this way we can broadcast
    # player-wide events). Socket2 on the other hand, identifies a player with
    # another account
    assert id0 == id1
    refute id1 == id2
  end
end
