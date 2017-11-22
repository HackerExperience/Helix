defmodule Helix.Test.Server.Setup do

  alias HELL.Password
  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Entity.Helper, as: EntityHelper

  @doc """
  - entity_id: Specify the entity that owns such server. Defaults to generating
  a random entity.

  Related data: Entity.t (when `opts[:entity_id]` is undefined)
  """
  def server(opts \\ []) do
    {server, entity} =
      if opts[:entity_id] do
        {server, _} = server_create_flow()
        EntityHelper.change_server_owner(server.server_id, opts[:entity_id])

        {server, nil}
      else
        server_create_flow()
      end

    {server, %{entity: entity}}
  end

  def server!(opts \\ []) do
    {server, _} = server(opts)
    server
  end

  @doc """
  Note that this function does NOT create related elements, like the motherboard
  - server_id: set the server_id.
  - motherboard_id: set the motherboard_id.
  - password: set the password.
  """
  def fake_server(opts \\ []) do
    server_id = Access.get(opts, :server_id, id())
    motherboard_id = Access.get(opts, :mobo_id, Component.ID.generate())
    password = Access.get(opts, :password, Password.generate(:server))

    server =
      %Server{
        server_id: server_id,
        motherboard_id: motherboard_id,
        password: password
      }

    {server, %{}}
  end

  @doc """
  Helper to create_or_fetch servers in a single command.
  """
  def create_or_fetch(nil),
    do: server!()
  def create_or_fetch(server_id) do
    ServerQuery.fetch(server_id)
  end

  @doc """
  Generates a random Server ID. It's the same as Server.ID.generate(), but may
  be helpful/more readable/more portable for some tests/contexts.
  """
  def id,
    do: Server.ID.generate()

  defp server_create_flow do
    {account, _} = AccountSetup.account()
    {:ok, %{entity: entity, server: server}} =
      AccountFlow.setup_account(account, nil)

    CacheHelper.purge_server(server.server_id)

    {server, entity}
  end
end
