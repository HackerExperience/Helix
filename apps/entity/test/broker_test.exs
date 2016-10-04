defmodule HELM.Entity.BrokerTest do
  use ExUnit.Case

  require Logger

  alias HELM.{Account, Entity}
  alias HELF.{Tester, Broker}

  setup do
    {:ok, _} = Application.ensure_all_started(:helf_broker)
    {:ok, _} = Application.ensure_all_started(:entity)
    {:ok, _} = Application.ensure_all_started(:account)

    # account email
    email = "entity@test01.com"
    puuid = "pseudo-uuid"

    with {:ok, account} <- Account.Controller.find(email),
         Account.Controller.remove_account(account),
         {:ok, entity} <- Entity.Controller.find_by(account_id: account.account_id),
      do: Entity.Controller.remove_entity(entity)

    with {:ok, entity} <- Entity.Controller.find_by(account_id: puuid),
      do: Entity.Controller.remove_entity(entity)

    payload = %{
      email: email,
      password: "12345678",
      password_confirmation: "12345678"
    }

    {:ok, payload: payload, puuid: puuid}
  end

  test "entity creation from account", %{payload: payload} do
    service = :entity_broker_tests_01
    {:ok, pid} = Tester.start_link(service, self())

    # This tester listens to event:acount:created casts
    Tester.listen(pid, :cast, "event:account:created")
    Tester.listen(pid, :cast, "event:entity:created")

    # Try to create the user
    {:ok, _} = Broker.call("account:create", payload)

    # Assert that account created event was received
    assert_receive {:cast, service, "event:account:created"}

    # Assert that the account_id saved
    {:ok, account_id} = Tester.assert(pid, :cast, "event:account:created")

    # Assert that account created event was received
    assert_receive {:cast, service, "event:entity:created"}

    # Assert that the entity_id was saved
    {:ok, entity_id} = Tester.assert(pid, :cast, "event:entity:created")

    # assert that the entity_id is binary
    assert is_binary(entity_id)

    # assert that the entity_id length is 25
    assert String.length(entity_id) == 25

    # get the entity
    {:ok, entity} = Entity.Controller.find(entity_id)

    # assert that the entity got the same id
    assert entity.account_id == account_id
  end

  test "direct entity creation", %{puuid: puuid} do
    service = :entity_broker_tests_02
    {:ok, pid} = Tester.start_link(service, self())

    # This tester listens to event:acount:created casts
    Tester.listen(pid, :cast, "event:account:created")
    Tester.listen(pid, :cast, "event:entity:created")

    # Try to create the user
    {:ok, entity} = Broker.call("entity:create", %{account_id: puuid})

    # cache the account id
    entity_id = entity.entity_id

    # assert that accound_id is string
    assert is_binary(entity_id)

    # assert string length
    assert String.length(entity_id) == 25

    # Assert that account created event was received
    assert_receive {:cast, service, "event:entity:created"}

    # Assert that the entity_id was saved
    {:ok, event_entity_id} = Tester.assert(pid, :cast, "event:entity:created")

    # assert that the entity_id is binary
    assert is_binary(entity_id)

    # assert that the entity_id length is 25
    assert String.length(entity_id) == 25

    # assert that the entity got the same id
    assert entity.entity_id == event_entity_id
  end
end
