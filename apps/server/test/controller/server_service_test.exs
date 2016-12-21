defmodule HELM.Server.Controller.ServerServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker
  alias HELM.Entity.Controller.EntityServer, as: EntityServerController

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
      assert params.email === account.email

      # FIXME
      :timer.sleep(100)

      entity_server =
        account.account_id
        |> EntityServerController.find()
        |> List.first()

      {_, {:ok, server}} = Broker.call("server:find", entity_server.server_id)

      assert account.account_id === entity_server.entity_id
      assert entity_server.server_id === server.server_id
    end
  end
end