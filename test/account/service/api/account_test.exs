defmodule Helix.Account.Service.API.AccountTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Model.Account
  alias Helix.Account.Repo
  alias Helix.Account.Service.API.Account, as: API
  alias Helix.Account.Service.API.Session, as: SessionAPI

  alias Helix.Account.Factory

  describe "create/1" do
    test "succeeds with valid input" do
      params = %{
        email: "this_is_actually+0@a_valid_email.com",
        username: "good_username0",
        password: "Would you very kindly let me in, please, good sir"
      }

      assert {:ok, acc = %Account{}} = API.create(params)
      Repo.delete!(acc) # FIXME: Ecto.Sandbox || on_exit
    end

    test "returns changeset when input is invalid" do
      params = %{}

      assert {:error, %Ecto.Changeset{}} = API.create(params)

      params = %{email: "invalid", username: "^invalid", password: "invalid"}
      assert {:error, %Ecto.Changeset{}} = API.create(params)
    end
  end

  describe "create/3" do
    test "succeeds with valid input" do
      email = "this_is_actually+1@a_valid_email.com"
      username = "good_username1"
      password = "Would you very kindly let me in, please, good sir"

      assert {:ok, acc = %Account{}} = API.create(email, username, password)
      Repo.delete!(acc) # FIXME: Ecto.Sandbox || on_exit
    end

    test "returns changeset when input is invalid" do
      result = API.create("", "", "")
      assert {:error, %Ecto.Changeset{}} = result

      result = API.create("invalid", "^invalid", "invalid")
      assert {:error, %Ecto.Changeset{}} = result
    end
  end

  describe "login/2" do
    test "succeeds when username and password are correct" do
      password = "foobar 123 password LetMeIn"
      account =
        Factory.insert(:account)
        |> Account.update_changeset(%{password: password})
        |> Repo.update!()

      assert {:ok, token} = API.login(account.username, password)
      assert {:ok, claims} = SessionAPI.validate_token(token)
      assert account.account_id == claims["sub"]
    end

    test "fails when provided with incorrect password" do
      account = Factory.insert(:account)

      assert {:error, _} = API.login(account.username, "incorrect pass")
    end

    test "cannot use email as login credential" do
      password = "foobar 123 password LetMeIn"
      account =
        Factory.insert(:account)
        |> Account.update_changeset(%{password: password})
        |> Repo.update!()

      assert {:error, _} = API.login(account.email, password)
    end
  end

  describe "logout/1 is idempotent" do
    password = "foobar 123 password LetMeIn"
    account = Factory.insert(:account, %{password: password})
    {:ok, token} = API.login(account.username, password)

    API.logout(token)
    API.logout(token)

    assert {:error, _} = SessionAPI.validate_token(token)
  end
end
