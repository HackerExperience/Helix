defmodule Helix.Account.Controller.AccountServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker

  @moduletag :umbrella

  setup do
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    params = %{email: email, password_confirmation: password, password: password}
    {:ok, params: params}
  end

  describe "account creation" do
    test "succeeds with proper data", %{params: params} do
      {_, {:ok, account}} = Broker.call("account:create", params)
      assert params.email === account.email
    end
  end
end