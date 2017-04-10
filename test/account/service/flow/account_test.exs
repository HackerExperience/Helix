defmodule Helix.Account.Service.Flow.AccountTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Service.Flow.Account, as: AccountFlow

  alias Helix.Account.Factory

  test "WIP, add tests" do
    account = Factory.insert(:account)
    assert :ok == AccountFlow.setup(account.account_id)
  end
end
