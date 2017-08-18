defmodule Helix.Test.Entity.Database.Setup do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Model.DatabaseBankAccount
  alias Helix.Entity.Model.DatabaseServer
  alias Helix.Entity.Repo, as: EntityRepo

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup

  @doc """
  See `fake_entry_server/1` doc
  """
  def entry_server(opts \\ []) do
    {entry, related} = fake_entry_server(opts)
    {:ok, inserted} = EntityRepo.insert(entry)

    {inserted, related}
  end

  @doc """
  - entity_id: generated entry belongs to that entity
  - server_id: server that will be added to the entry
  - password: password stored on database entry

  Related data: Server.t, Entity.t
  """
  def fake_entry_server(opts \\ []) do

    entity =
      EntitySetup.create_or_fetch(opts[:entity_id])

    {server, nip} =
      if opts[:server_id] do
        {:ok, [nip]} = CacheQuery.from_server_get_nips(opts[:server_id])
        server = ServerQuery.fetch(opts[:server_id])

        {server, nip}
      else
        {server, _} = ServerSetup.server()
        {:ok, [nip]} = CacheQuery.from_server_get_nips(server.server_id)

        {server, nip}
      end

    password = Access.get(opts, :password, nil)

    entry =
      %DatabaseServer{
        entity_id: entity.entity_id,
        network_id: nip.network_id,
        server_ip: nip.ip,
        server_id: server.server_id,
        server_type: :vpc,
        password: password,
        alias: nil,
        notes: nil,
        last_update: DateTime.utc_now()
      }

    {entry, %{server: server, entity: entity}}
  end

  @doc """
  See `fake_entry_bank_account/1` doc
  """
  def entry_bank_account(opts \\ []) do
    {entry, related} = fake_entry_bank_account(opts)
    {:ok, inserted} = EntityRepo.insert(entry)

    {inserted, related}
  end

  @doc """
  - entity_id: generated entry will belong to that entity
  - acc: bank account to store on the database (`BankAccount.t`)

  Related data: BankAccount.t, Entity.t
  """
  def fake_entry_bank_account(opts \\ []) do
    entity = EntitySetup.create_or_fetch(opts[:entity_id])

    acc = Access.get(opts, :acc, BankSetup.account!())

    atm_ip = ServerQuery.get_ip(acc.atm_id, NetworkHelper.internet_id())

    entry =
      %DatabaseBankAccount{
        entity_id: entity.entity_id,
        atm_id: acc.atm_id,
        account_number: acc.account_number,
        atm_ip: atm_ip,
        known_balance: nil,
        notes: nil,
        last_login_date: nil,
        last_update: DateTime.utc_now()
      }

    {entry, %{acc: acc, entity: entity}}
  end
end
