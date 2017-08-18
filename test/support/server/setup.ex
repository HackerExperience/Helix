defmodule Helix.Test.Server.Setup do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Cache.Helper, as: CacheHelper

  @doc """
  - entity_id: Specify the entity that owns such server (TODO). Defaults to
  generating a random entity.

  Related data: Entity.t
  """
  def server(opts \\ []) do
    {server, entity} =
      if opts[:entity_id] do
        raise "todo"
      else
        {account, _} = AccountSetup.account()
        {:ok, %{entity: entity, server: server}} =
          AccountFlow.setup_account(account)

        :timer.sleep(100)
        CacheHelper.purge_server(server.server_id)

        {server, entity}
      end

    {server, %{entity: entity}}
  end

  @doc """
  Helper to create_or_fetch servers in a single command.
  """
  def create_or_fetch(nil),
    do: server()
  def create_or_fetch(server_id) do
    ServerQuery.fetch(server_id)
  end
end
