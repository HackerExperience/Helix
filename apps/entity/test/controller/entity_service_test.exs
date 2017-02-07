defmodule Helix.Entity.Controller.EntityServiceTest do

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
      password_confirmation: password,
      password: password
    }

    {:ok, params: params}
  end

  describe "entity creation" do
    test "after account creation", %{params: params} do
      {_, {:ok, account}} = Broker.call("account.create", params)
      msg = %{entity_id: account.account_id}
      {_, {:ok, entity}} = Broker.call("entity.find", msg)
      assert "account" === entity.entity_type
      assert account.account_id === entity.entity_id
    end
  end
end