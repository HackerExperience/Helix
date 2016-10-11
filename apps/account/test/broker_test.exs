defmodule HELM.Account.BrokerTest do
  use ExUnit.Case

  require Logger

  alias HELM.Account
  alias HELF.{Tester, Broker}

  setup do
    {:ok, _} = Application.ensure_all_started(:helf_router)
    {:ok, _} = Application.ensure_all_started(:helf_broker)
    {:ok, _} = Application.ensure_all_started(:account)

    # account email
    email = "account@test02.com"

    # remove existing user
    case HELM.Account.Controller.find_with_email(email) do
      {:ok, account} -> HELM.Account.Controller.delete(account.account_id)
      {:error, _} -> nil
    end

    {:ok, email: email}
  end

  test "account creation messaging", %{email: email} do
    service = :account_broker_tests_01
    {:ok, pid} = Tester.start_link(service, self())

    # This tester listens to event:acount:created casts
    Tester.listen(pid, :cast, "event:account:created")

    # Example account payload
    account = %{
      email: email,
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
    assert_receive {:cast, service, "event:account:created"}

    # Assert that the state was saved
    {:ok, event_accound_id} = Tester.assert(pid, :cast, "event:account:created")

    # Asset that id is a string
    assert account_id == event_accound_id
  end
end
