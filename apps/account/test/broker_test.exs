defmodule HELM.Account.BrokerTest do
  use ExUnit.Case

  require Logger

  alias HELL.Random, as: HRand
  alias HELM.Account.Controller, as: AccountCtrl
  alias HELF.Broker

  setup do
    email = HRand.random_numeric_string()
    {:ok, email: email}
  end

  test "account creation messaging", data do
    # service = :account_broker_tests_01
    # {:ok, pid} = Tester.start_link(service, self())

    # This tester listens to event:acount:created casts
    # Tester.listen(pid, :cast, "event:account:created")

    # Example account payload
    account = %{
      email: data.email,
      password: "12345678",
      password_confirmation: "12345678"
    }

    # Try to create the user
    {_request, account} = Broker.call("account:create", account)

    # cache the account id
    account_id = account.account_id

    # assert that accound_id is string
    assert is_binary(account_id)

    # assert string length
    assert String.length(account_id) == 25

    # Assert that message was received
    # assert_receive {:cast, service, "event:account:created"}

    # Assert that the state was saved
    # {:ok, event_accound_id} = Tester.assert(pid, :cast, "event:account:created")

    # Asset that id is a string
    # assert account_id == event_accound_id
  end
end
