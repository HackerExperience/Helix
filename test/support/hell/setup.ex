defmodule HELL.TestHelper.Setup do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Factory, as: AccountFactory
  alias Helix.Cache.Helper, as: CacheHelper

  def server do
    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    :timer.sleep(100)
    CacheHelper.purge_server(server.server_id)

    {server, account}
  end
end
