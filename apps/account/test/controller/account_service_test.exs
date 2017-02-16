defmodule Helix.Account.Controller.AccountServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker

  alias Helix.Account.Factory

  @moduletag :umbrella

  describe "account creation" do
    test "succeeds with proper data" do
      params = Factory.params_for(:account)
      {_, {:ok, account}} = Broker.call("account.create", params)

      assert params.email === account.email
    end
  end
end