defmodule Helix.Test.Entity.Database.Setup do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Repo, as: EntityRepo

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup

  @doc """
  See `fake_entry_server/1` doc
  """
  def entry_server(opts \\ []) do
    {entry, related} = fake_entry_server(opts)
    {:ok, inserted} = EntityRepo.insert(entry)

    entry = Map.replace!(inserted, :viruses, [])

    {entry, related}
  end

  @doc """
  - entity_id: generated entry belongs to that entity
  - server_id: server that will be added to the entry
  - password: password stored on database entry. Defaults to nil.

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
      %Database.Server{
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
  - real_entity: Whether it should create an entity. Defaults to true.

  Related data: BankAccount.t, Entity.t (nil if not `real_entity`)
  """
  def fake_entry_bank_account(opts \\ []) do
    {entity, entity_id} =
      if opts[:real_entity] == false do
        {nil, Entity.ID.generate()}
      else
        entity = EntitySetup.create_or_fetch(opts[:entity_id])

        {entity, entity.entity_id}
      end

    acc = Access.get(opts, :acc, BankSetup.account!())

    atm_ip = ServerQuery.get_ip(acc.atm_id, NetworkHelper.internet_id())

    entry =
      %Database.BankAccount{
        entity_id: entity_id,
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

  @doc """
  See doc on `fake_entry_virus/1`
  """
  def entry_virus(opts \\ []) do
    {entry, related} = fake_entry_virus(opts)
    inserted = EntityRepo.insert!(entry)
    {inserted, related}
  end

  @doc """
  Opts:
  - entity_id: Set `entity_id`.
  - server_id: Set `server_id`.
  - file_id: Set `file_id`. Defaults to random file id.
  - from_entry: Gather `entity_id` and `server_id` from the given
    `Database.Server`. Overrides `entity_id` and `server_id` opts
  """
  def fake_entry_virus(opts \\ []) do
    if is_nil(opts[:entity_id]) and is_nil(opts[:from_entry]),
      do: raise "I need either `entity_id` or `from_entry` opt"

    entity_id =
      cond do
        opts[:from_entry] ->
          opts[:from_entry].entity_id

        opts[:entity_id] ->
          opts[:entity_id]

        true ->
          Entity.ID.generate()
      end

    server_id =
      cond do
      opts[:from_entry] ->
        opts[:from_entry].server_id

      opts[:server_id] ->
        opts[:server_id]

      true ->
        ServerHelper.id()
    end

    file_id = Keyword.get(opts, :file_id, SoftwareHelper.id())

    entry =
      %Database.Virus{
        entity_id: entity_id,
        server_id: server_id,
        file_id: file_id
      }

    {entry, %{}}
  end
end
