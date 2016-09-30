defmodule HELM.Account.BrokerTest do
  use ExUnit.Case

  require Logger

  alias HELF.{Tester, Broker}

  setup do
    {:ok, _} = Application.ensure_all_started(:helf_router)
    {:ok, _} = Application.ensure_all_started(:helf_broker)
    {:ok, pid} = Tester.start_link(self())
    {:ok, pid: pid}
  end

  test "account creation messaging", %{pid: pid} do
    # This tester listens to event:acount:created casts
    Tester.listen(pid, :cast, :test_account_creation, "event:account:created")

    # Example account payload
    account = %{
      email: "example@test.com",
      password: "12345678",
      password_confirmation: "12345678"
    }

    # Try to create the user
    {:ok, account} = HELF.Broker.call("account:create", account)

    # cache the account id
    account_id = account.account_id

    # assert that accound_id is string
    assert is_binary(account_id)

    # assert string length
    assert String.length(account_id) == 25

    # Assert that message was received
    assert_receive {:cast, "event:account:created"}

    # Assert that the state was saved
    {:ok, event_accound_id} = Tester.assert(pid, :cast, "event:account:created")

    # Asset that id is a string
    assert account_id == event_accound_id
  end
end
