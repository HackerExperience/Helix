defmodule Helix.Server.Controller.ServerServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker

  @moduletag :umbrella

  defp forward_broker_cast(topic) do
    ref = make_ref()

    Broker.subscribe(topic, cast: fn pid, _, data, _ ->
      send pid, {ref, data}
    end)

    ref
  end

  describe "after account creation" do
    setup do
      email = Burette.Internet.email()
      password = Burette.Internet.password()
      params = %{email: email, password_confirmation: password, password: password}
      {:ok, params: params}
    end

    test "server is created", %{params: params} do
      ref = forward_broker_cast("event:server:created")

      {_, {:ok, account}} =
        Broker.call("account:create", params)
      assert_receive {^ref, {server_id, entity_id}}
      assert account.account_id == entity_id
      assert {_, {:ok, _}} = Broker.call("server:query", server_id)
    end

    test "server attaches a motherboard", %{params: params} do
      ref = forward_broker_cast("event:server:attached")

      {_, {:ok, _}} =
        Broker.call("account:create", params)
      assert_receive {^ref, msg}
      assert {_, {:ok, server}} = Broker.call("server:query", msg.server_id)
      assert server.motherboard_id === msg.motherboard_id
    end
  end
end