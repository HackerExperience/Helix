defmodule Helix.Server.Controller.ServerServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker

  @moduletag :umbrella

  setup do
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    params = %{email: email, password_confirmation: password, password: password}
    {:ok, params: params}
  end

  describe "server creation" do
    test "after account creation", %{params: params} do
      {_, {:ok, account}} = Broker.call("account:create", params)

      ref = make_ref()
      Broker.subscribe("event:server:created", cast: fn pid, _, data, _ ->
        send pid, {ref, data}
      end)

      assert_receive {^ref, {server_id, entity_id}}, 200
      assert account.account_id == entity_id
      assert {_, {:ok, _}} = Broker.call("server:query", server_id)
    end
  end
end