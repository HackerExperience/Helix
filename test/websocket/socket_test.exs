defmodule Helix.Websocket.SocketTest do

  use Helix.Test.Case.Integration

  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Websocket.Socket

  alias Helix.Test.Account.Factory, as: AccountFactory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  describe "socket access" do
    test "connection with valid token is allowed" do
      account = AccountFactory.insert(:account)
      {:ok, token} = SessionAction.generate_token(account)

      assert {:ok, _} = connect(Socket, %{"token" => token})
    end

    test "'public' connection is refused" do
      assert :error = connect(Socket, %{})
    end

    test "connection with wrong token is refused" do
      assert :error = connect(Socket, %{"token" => "invalid"})
    end
  end
end
