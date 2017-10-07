defmodule Helix.Test.Universe.NPC.Helper do

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Repo, as: EntityRepo
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Repo, as: HardwareRepo
  alias Helix.Network.Model.DNS.Anycast
  alias Helix.Network.Repo, as: NetworkRepo
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo, as: ServerRepo
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.Bank
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.NPC.Model.Seed
  alias Helix.Universe.Repo, as: UniverseRepo

  @doc """
  Ensures database does not contain any NPC information.

  Note that some residues are left behind, like hardware components (cpu, hdd,
  motherboard etc). It's OK, since as far as NPC is concerned, those components
  are dynamically generated.
  """
  def empty_database do

    # Bank stuff
    UniverseRepo.delete_all(BankTransfer)
    UniverseRepo.delete_all(BankAccount)
    UniverseRepo.delete_all(ATM)
    UniverseRepo.delete_all(Bank)

    # Remove NPC
    UniverseRepo.delete_all(NPC)

    # Remove Entity
    EntityRepo.delete_all(EntityServer)
    EntityRepo.delete_all(Entity)

    # Remove Server
    ServerRepo.delete_all(Server)

    # Remove DNS
    NetworkRepo.delete_all(Anycast)

    # Remove NetworkConnection (ips)
    HardwareRepo.delete_all(NetworkConnection)

    # Remove potentially cached data
    CacheHelper.empty_cache()
  end

  def random do
    # Guaranteed to be random
    npc = Seed.search_by_type(:download_center)
    server = List.first(npc.servers)

    {npc, server.static_ip}
  end

  def download_center do
    dc = Seed.search_by_type(:download_center)
    server = List.first(dc.servers)

    {dc, server.static_ip}
  end

  def bank do
    bank = Seed.search_by_type(:bank)
    server = List.first(bank.servers)

    {bank, server.static_ip}
  end

end
