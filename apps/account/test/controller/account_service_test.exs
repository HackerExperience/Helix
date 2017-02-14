defmodule Helix.Account.Controller.AccountServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker
  alias HELL.TestHelper.Random

  @moduletag :umbrella

  setup do
    name = Random.username()
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    params = %{
      username: name,
      email: email,
      password: password
    }
    {:ok, params: params}
  end

  describe "account creation" do
    test "succeeds with proper data", %{params: params} do
      {_, {:ok, account}} = Broker.call("account.create", params)
      assert params.email === account.email
    end
  end
end