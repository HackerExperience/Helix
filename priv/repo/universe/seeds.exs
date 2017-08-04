defmodule Helix.Universe.NPC.Seed do

  alias Helix.Universe.Repo
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.NPC.Model.NPCType
  alias Helix.Universe.NPC.Model.Seed
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal
  alias Helix.Hardware.Action.Flow.Hardware, as: HardwareFlow
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo, as: ServerRepo
  alias Helix.Network.Action.DNS, as: DNSAction
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Cache.Action.Cache, as: CacheAction

  def migrate do
    npcs = Seed.seed()

    Repo.transaction fn ->

      # Ensure the DB has the basic NPC types
      add_npc_types()

      Enum.map(npcs, fn (entry) ->

        IO.puts("entry -> #{inspect entry}")

        npc = %NPC{npc_id: entry.id, npc_type: entry.type}
        entity = %Entity{entity_id: npc.npc_id, entity_type: :npc}
        entity_params = %{entity_id: npc.npc_id, entity_type: :npc}

        # Create NPC
        unless NPCInternal.fetch(npc.npc_id) do
          Repo.insert!(npc, on_conflict: :nothing)
        end

        # Create Entity
        unless EntityInternal.fetch(npc.npc_id) do
          EntityInternal.create(entity_params)
        end

        Enum.map(entry.servers, fn(cur) ->
          create_server(cur, entry, npc, entity)
        end)

        create_dns(entry, npc)

        create_specialization(entry, npc)
      end)
    end

    # Give time to commit previous transactions
    :timer.sleep(500)

    clean_cache(npcs)
  end

  def add_npc_types do
    Enum.each(NPCType.possible_types(), fn type ->
      Repo.insert!(%NPCType{npc_type: type}, on_conflict: :nothing)
    end)
  end

  def create_server(entry_server, entry, npc, entity) do
    unless ServerInternal.fetch(entry_server.id) do

      # Create Server
      server = %{server_id: entry_server.id, server_type: :desktop}
        |> Server.create_changeset()
        |> Ecto.Changeset.cast(%{server_id: entry_server.id}, [:server_id])
        |> ServerRepo.insert!

      # Create & attach mobo
      {:ok, motherboard_id} = HardwareFlow.setup_bundle(entity)
      {:ok, server} = ServerInternal.attach(server, motherboard_id)

      # Link to Entity
      {:ok, _} = EntityInternal.link_server(entity, server.server_id)

      # Change IP if a static one was specified
      if entry_server.static_ip do
        nc = motherboard_id
          |> MotherboardInternal.fetch()
          |> MotherboardInternal.get_networks()
          |> Enum.find(&(&1.network_id == "::"))

        unless nc.ip == entry_server.static_ip do
          NetworkConnectionInternal.update_ip(nc, entry_server.static_ip)
        end
      end
    end
  end

  def create_dns(entry, npc) do
    if entry.anycast do
      unless DNSInternal.lookup_anycast(entry.anycast) do
        DNSAction.register_anycast(entry.anycast, npc.npc_id)
      end
    end
  end

  def clean_cache(npcs) do
    # Ensure nothing is left on cache
    # FIXME: This deletes all cache entries from all (seeded) NPCs. Might cause
    # load spikes on production. Filter out to purge only servers who were added
    # during the migration.
    Enum.map(npcs, fn(npc) ->
      Enum.map(npc.servers, fn(server) ->
        CacheAction.purge_server(server.id)
      end)
    end)
  end

  def create_specialization(entry = %{type: :bank}, npc) do
    # Bank
  end
  def create_specialization(entry = %{type: :atm}, npc) do
    # Atm
  end
  def create_specialization(%{custom: false}, npc),
    do: :ok
  def create_specialization(_, _),
    do: raise "Invalid seed config"

end

alias Helix.Universe.NPC.Seed

Seed.migrate()
