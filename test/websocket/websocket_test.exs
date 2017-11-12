defmodule Helix.WebsocketTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Websocket
  alias Helix.Account.Action.Session, as: SessionAction

  alias Helix.Test.Account.Setup, as: AccountSetup

  @endpoint Helix.Endpoint

  describe "socket access" do
    test "connection with valid token is allowed" do
      {account, _} = AccountSetup.account()

      {:ok, token} = SessionAction.generate_token(account)

      params =
        %{
          "token" => token,
          "client" => "web1"
        }

      assert {:ok, socket} = connect(Websocket, params)

      assert socket.assigns.account_id == account.account_id
      assert socket.assigns.client == :web1
    end

    test "invalid client fallbacks to :unknown" do
      {account, _} = AccountSetup.account()
      {:ok, token} = SessionAction.generate_token(account)

      # `p1` has an invalid `client` defined
      p1 =
        %{
          "token" => token,
          "client" => "i_do_not_exist"
        }

      # `p2` does not define `client` at all
      p2 =
        %{
          "token" => token
        }

      assert {:ok, s1} = connect(Websocket, p1)
      assert {:ok, s2} = connect(Websocket, p2)

      # On both cases, we fallback `client` to `unknown`
      assert s1.assigns.client == :unknown
      assert s2.assigns.client == :unknown
    end

    test "'public' connection is refused" do
      assert :error = connect(Websocket, %{})
    end

    test "connection with wrong token is refused" do
      assert :error =
        connect(Websocket, %{"token" => "invalid", "client" => "mobile1"})
    end
  end
end
