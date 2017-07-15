alias Helix.Universe.Repo
alias Helix.Universe.NPC.Model.NPC
alias Helix.Universe.NPC.Model.NPCType
alias Helix.Universe.NPC.Model.Seed
alias Helix.Entity.Model.Entity
alias Helix.Entity.Query.Entity, as: EntityQuery
alias Helix.Entity.Action.Entity, as: EntityAction
alias Helix.Hardware.Action.Flow.Hardware, as: HardwareFlow
alias Helix.Server.Query.Server, as: ServerQuery
alias Helix.Server.Action.Server, as: ServerAction
alias Helix.Server.Model.Server
alias Helix.Server.Repo, as: ServerRepo
alias Helix.Network.Action.DNS, as: DNSAction
alias Helix.Network.Internal.DNS, as: DNSInternal

npcs = Seed.seed()

Repo.transaction fn ->
  # NPC Types
  Enum.each(NPCType.possible_types(), fn type ->
    Repo.insert!(%NPCType{npc_type: type}, on_conflict: :nothing)
  end)

  Enum.map(npcs, fn (entry) ->

    npc = %NPC{npc_id: entry.id, npc_type: entry.type}
    entity = %Entity{entity_id: npc.npc_id, entity_type: :npc}

    # Create NPC
    Repo.insert!(npc, on_conflict: :nothing)

    # Create Entity
    unless EntityQuery.fetch(npc.npc_id) do
      EntityAction.create_from_specialization(npc)
    end

    Enum.map(entry.servers, fn(cur) ->
      unless ServerQuery.fetch(cur.id) do

        # Create Server
        server = %{server_id: cur.id, server_type: :desktop}
        |> Server.create_changeset()
        |> Ecto.Changeset.cast(%{server_id: cur.id}, [:server_id])
        |> ServerRepo.insert!

        # Create & attach mobo
        {:ok, motherboard_id} = HardwareFlow.setup_bundle(entity)
        {:ok, server} = ServerAction.attach(server, motherboard_id)

        # Link to Entity
        {:ok, _} = EntityAction.link_server(entity, cur.id)

        if cur.static_ip do
          # TODO
        end
      end

      # DNS entries
      if entry["anycast"] do
        unless DNSInternal.lookup_anycast(entry["anycast"]) do
          DNSAction.register_anycast(entry["anycast"], npc.npc_id)
        end
      end
    end)
  end)
end
