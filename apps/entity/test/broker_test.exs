defmodule HELM.Entity.BrokerTest do
  use ExUnit.Case, async: false

  require Logger

  alias HELM.{Account, Entity}
  alias HELF.{Tester, Broker}

  setup do
    {:ok, _} = Application.ensure_all_started(:helf_broker)
    {:ok, pid} = Tester.start_link(self())

    # account email
    email = "entity@test01.com"

    with {:ok, account} <- Account.Controller.find(email),
         Account.Controller.remove_account(account),
         {:ok, entity} <- Entity.Controller.find_by(account_id: account.account_id),
      do: Entity.Controller.remove_entity(entity)

    with {:ok, entity} <- Entity.Controller.find_by(account_id: email),
      do: Entity.Controller.remove_entity(entity)

    payload = %{
      email: email,
      password: "12345678",
      password_confirmation: "12345678"
    }

    {:ok, pid: pid, payload: payload}
  end

  test "entity creation from account", %{pid: pid, payload: payload} do
    # This tester listens to event:acount:created casts
    Tester.listen(pid, :cast, :test_entity_creation1, "event:account:created")
    Tester.listen(pid, :cast, :test_entity_creation1, "event:entity:created")

    # Try to create the user
    {:ok, _} = Broker.call("account:create", payload)

    # Assert that account created event was received
    assert_receive {:cast, "event:account:created"}

    # Assert that the account_id saved
    {:ok, account_id} = Tester.assert(pid, :cast, "event:account:created")

    # Assert that account created event was received
    assert_receive {:cast, "event:entity:created"}

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

  test "direct entity creation", %{pid: pid, payload: payload} do
    # This tester listens to event:acount:created casts
    Tester.listen(pid, :cast, :test_entity_creation2, "event:account:created")
    Tester.listen(pid, :cast, :test_entity_creation2, "event:entity:created")

    # Try to create the user
    {:ok, entity} = Broker.call("entity:create", %{account_id: payload.email})

    # cache the account id
    entity_id = entity.entity_id

    # assert that accound_id is string
    assert is_binary(entity_id)

    # assert string length
    assert String.length(entity_id) == 25

    # Assert that account created event was received
    assert_receive {:cast, "event:entity:created"}

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
