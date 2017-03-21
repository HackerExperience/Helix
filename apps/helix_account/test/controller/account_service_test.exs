defmodule Helix.Account.Controller.AccountServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  @moduletag :umbrella

  describe "account creation" do
    test "succeeds with valid params" do
      params = Factory.params_for(:account)
      {_, {:ok, account}} = Broker.call("account.create", params)

      assert params.email === account.email
    end
  end

  describe "login" do
    test "uses username and password" do
      password = Burette.Internet.password()
      account =
        Factory.insert(:account)
        |> Account.update_changeset(%{password: password})
        |> Repo.update!()

      params = %{username: account.username, password: password}

      assert {_, {:ok, _}} = Broker.call("account.login", params)
    end

    test "fails with any invalid combination" do
      password = Burette.Internet.password()
      account =
        Factory.insert(:account)
        |> Account.update_changeset(%{password: password})
        |> Repo.update!()

      permutations = [
        %{username: account.username, password: "invalid_password"},
        %{username: account.email, password: password},
        %{username: account.account_id, password: password}
      ]

      Enum.each(permutations, fn params ->
        assert {_, {:error, _}} = Broker.call("account.login", params)
      end)
    end
  end
end