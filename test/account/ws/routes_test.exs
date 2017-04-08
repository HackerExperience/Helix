defmodule Helix.Account.WS.RoutesTest do

  use ExUnit.Case, async: true

  alias Helix.Router.Socket.Player, as: Socket
  alias Helix.Account.Controller.Session

  alias Helix.Account.Factory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  setup do
    account = Factory.insert(:account)
    {:ok, jwt, _} = Session.create(account)
    {:ok, socket} = connect(Socket, %{token: jwt})
    {:ok, _, socket} = join(socket, "requests")

    {:ok, account: account, socket: socket}
  end

  test "logout closes socket", context do
    push(context.socket, "account.logout")

    :timer.sleep(100)

    refute Process.alive? context.socket.channel_pid
    # The token has been invalidated so we should not be able to use it again
    assert :error == connect(Socket, %{token: context.socket.assigns.token})
  end
end

defmodule Helix.Account.WS.PublicRoutesTest do

  use ExUnit.Case, async: true

  alias Helix.Router.Socket.Public, as: Socket
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo
  alias Helix.Account.Service.API.Session

  alias Helix.Account.Factory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  def requests_driver do
    {:ok, socket} = connect(Socket, %{})
    {:ok, _, socket} = join(socket, "requests")

    socket
  end

  describe "login" do
    test "returns error when using invalid credentials" do
      socket = requests_driver()

      credentials = %{"username" => "foo", "password" => "invalid"}

      ref = push socket, "account.login", credentials

      # Login requests should have a longer timeout because bcrypt might make
      # them slow
      assert_reply ref, :error, %{message: msg}, 5_000
      assert msg =~ "not found"
    end

    test "returns bearer token on success" do
      socket = requests_driver()

      password = "foobar!!!123 omg let me in, open sesame"
      account = Factory.insert(:account, password: password)
      credentials = %{"username" => account.username, "password" => password}

      ref = push socket, "account.login", credentials

      # Login requests should have a longer timeout because bcrypt might make
      # them slow
      assert_reply ref, :ok, %{token: token}, 5_000
      assert {:ok, _} = Session.validate_token(token)
    end
  end

  describe "create" do
    test "returns a map with the new account on succes" do
      params = Factory.params_for(:account)

      socket = requests_driver()

      ref = push socket, "account.create", params

      assert_reply ref, :ok, acc = %{}, 5_000
      assert Repo.get(Account, acc.account_id)
    end
  end
end
