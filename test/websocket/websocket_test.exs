defmodule Helix.WebsocketTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket
  alias Helix.Account.Action.Session, as: SessionAction

  alias Helix.Test.Account.Factory, as: AccountFactory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  describe "socket access" do
    test "connection with valid token is allowed" do
      account = AccountFactory.insert(:account)
      {:ok, token} = SessionAction.generate_token(account)

      assert {:ok, _} = connect(Websocket, %{"token" => token})
    end

    test "'public' connection is refused" do
      assert :error = connect(Websocket, %{})
    end

    test "connection with wrong token is refused" do
      assert :error = connect(Websocket, %{"token" => "invalid"})
    end
  end
end
