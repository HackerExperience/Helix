defmodule AuthTest do
  use ExUnit.Case
  doctest Auth

  alias Auth.Account.JWT

  test "account JWT creation" do
    account = %Account.AccountModel{email: "foo@bar.com"}

    assert {:reply, {:ok, %{"token" => _}}} = JWT.generate(account)
  end

  test "account JWT verification" do
    account = %Account.AccountModel{email: "foo@bar.com"}

    {:reply, {:ok, %{"token" => jwt}}} = JWT.generate(user)

    assert {:reply, :ok} == JWT.verify(jwt)
  end
end
