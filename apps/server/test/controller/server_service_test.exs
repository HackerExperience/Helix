defmodule Helix.Server.Controller.ServerServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker
  alias HELL.TestHelper.Random

  @moduletag :umbrella

  # HACK: this method is calling methods from another domain instead of Broker
  defp server_of_account(account_id) do
    # entity has a list of servers
    with \
      [entity_server] <- Helix.Entity.Controller.EntityServer.find(account_id),
      {:ok, server} <- Helix.Server.Controller.Server.find(entity_server.server_id)
    do
      {:ok, server}
    else
      _ ->
        {:error, :not_found}
    end
  end

  describe "after account creation" do
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

    test "server is created", %{params: params} do
      {_, {:ok, account}} = Broker.call("account.create", params)

      # TODO: removing this sleep depends on T412
      :timer.sleep(100)

      assert {:ok, _} = server_of_account(account.account_id)
    end

    test "server attaches a motherboard", %{params: params} do
      {_, {:ok, account}} = Broker.call("account.create", params)

      # TODO: removing this sleep depends on T412
      :timer.sleep(100)

      {:ok, server} = server_of_account(account.account_id)

      assert server.motherboard_id
    end
  end

  describe "hardware resources" do

    @tag skip: "pending"
    test "can be retrieved from hardware service" do
      server_id = Random.pk()

      topic = "server.hardware.resources"
      msg = %{server_id: server_id}

      assert {_, {:ok, res}} = Broker.call(topic, msg)
      assert %{cpu: _, ram: _, dlk: _, ulk: _} = res
    end
  end
end