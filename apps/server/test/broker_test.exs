defmodule HELM.Server.BrokerTest do
  use ExUnit.Case, async: false

  require Logger

  alias HELM.{Account, Entity, Server}
  alias HELF.{Tester, Broker}

  setup do
    {:ok, _} = Application.ensure_all_started(:helf_router)
    {:ok, _} = Application.ensure_all_started(:helf_broker)

    # account email
    email = "account@test03.com"

    # remove acount and entity
    with {:ok, account} <- Account.Controller.find(email),
         Account.Controller.remove_account(account),
         {:ok, entity} <- Entity.Controller.find_by(account_id: account.account_id),
      do: Entity.Controller.remove_entity(entity)

    # remove server created with pseudo-id (email)
    #with {:ok, entity} <- Server.Controller.find(email),
    #  do: Entity.Controller.remove_entity(entity)

    # Example account payload
    account = %{
      email: email,
      password: "12345678",
      password_confirmation: "12345678"
    }

    {:ok, email: email, payload: account}
  end

  test "server creation from account messaging", %{email: email, payload: payload} do
    {:ok, pid} = Tester.start_link(service, self())

    # This tester only cares about
    #Tester.listen(pid, :cast, :test_server_creation1, "event:entity:created")

    #IO.inspect Server.Repo.all(Server.Schema)

    # Try to create the user
    {:ok, _} = HELF.Broker.call("account:create", payload)

    # assert that entit
    #assert_receive {:cast, "event:entity:created"}

    #{:ok, entity_id} = Tester.assert(pid, :cast, "event:entity:created")

    #IO.puts "test"

    #IO.inspect entity_id
  end
end
