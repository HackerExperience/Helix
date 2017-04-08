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
    {:ok, _, socket} = join(socket, "requests", %{})

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
