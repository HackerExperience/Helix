defmodule HELM.Server.BrokerTest do
  use ExUnit.Case, async: false

  require Logger

  alias HELM.{Account, Entity, Server}
  alias HELF.{Tester, Broker}

  setup do
    {:ok, _} = Application.ensure_all_started(:helf_router)
    {:ok, _} = Application.ensure_all_started(:helf_broker)
    {:ok, _} = Application.ensure_all_started(:entity)
    {:ok, _} = Application.ensure_all_started(:account)

    # account email
    email = "account@test03.com"
    puuid = "pseudo-uuid"

    # remove acount and entity
    with {:ok, account} <- Account.Controller.find(email),
         Account.Controller.remove_account(account),
         {:ok, entity} <- Entity.Controller.find_by(account_id: account.account_id),
      do: Entity.Controller.remove_entity(entity)

    # Example account payload
    account = %{
      email: email,
      password: "12345678",
      password_confirmation: "12345678"
    }

    {:ok, payload: account, puuid: puuid}
  end

  test "server creation from account messaging", %{payload: payload} do
    # Tester id
    service = :server_broker_tests_01

    # Create a tester instance
    {:ok, pid} = Tester.start_link(service, self())

    # This tester only cares about server
    Tester.listen(pid, :cast, "event:server:created")

    # Try to create the user
    {:ok, _} = HELF.Broker.call("account:create", payload)

    # Assert that server was created
    assert_receive {:cast, service, "event:server:created"}, 5000

    # Get the server id
    {:ok, server_id} = Tester.assert(pid, :cast, "event:server:created")

    # assert that the server_id is binary
    assert is_binary(server_id)

    # assert that the server_id length is 25
    assert String.length(server_id) == 25

    # assert that the entity is on db
    #{:ok, _} = Entity.Controller.find(entity_id)
  end

  test "direct server creation", %{payload: payload} do
  end
end
