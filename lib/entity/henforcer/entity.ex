defmodule Helix.Entity.Henforcer.Entity do

  import Helix.Henforcer

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Software.Henforcer.Storage, as: StorageHenforcer
  alias Helix.Software.Henforcer.Virus, as: VirusHenforcer
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.Virus
  alias Helix.Server.Henforcer.Component, as: ComponentHenforcer
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery

  @type entity_exists_relay :: %{entity: Entity.t}
  @type entity_exists_error ::
    {false, {:entity, :not_found}, entity_exists_relay}

  @spec entity_exists?(Entity.id) ::
    {true, entity_exists_relay}
    | entity_exists_error
  @doc """
  Henforces the given Entity exists.
  """
  def entity_exists?(entity_id = %Entity.ID{}) do
    with entity = %Entity{} <- EntityQuery.fetch(entity_id) do
      reply_ok(relay(%{entity: entity}))
    else
      _ ->
        reply_error({:entity, :not_found})
    end
  end

  @type owns_server_relay :: %{entity: Entity.t, server: Server.t}
  @type owns_server_relay_partial :: owns_server_relay
  @type owns_server_error ::
    {false, {:server, :not_belongs}, owns_server_relay_partial}
    | entity_exists_error
    | ServerHenforcer.server_exists_error

  @spec owns_server?(Entity.idt, Server.idt) ::
    {true, owns_server_relay}
    | owns_server_error
  @doc """
  Henforces the Entity is the owner of the given server.
  """
  def owns_server?(entity_id = %Entity.ID{}, server) do
    henforce entity_exists?(entity_id) do
      owns_server?(relay.entity, server)
    end
  end

  def owns_server?(entity, server_id = %Server.ID{}) do
    henforce(ServerHenforcer.server_exists?(server_id)) do
      owns_server?(entity, relay.server)
    end
  end

  def owns_server?(entity = %Entity{}, server = %Server{}) do
    with \
      owner = %Entity{} <- EntityQuery.fetch_by_server(server),
      true <- owner == entity
    do
      reply_ok()
    else
      _ ->
        reply_error({:server, :not_belongs})
    end
    |> wrap_relay(%{entity: entity, server: server})
  end

  @type owns_component_relay ::
    %{entity: Entity.t, component: Component.t, owned_components: [Component.t]}
  @type owns_component_relay_partial :: owns_component_relay
  @type owns_component_error ::
    {false, {:component, :not_belongs}, owns_component_relay_partial}
    | ComponentHenforcer.component_exists_error
    | entity_exists_error

  @spec owns_component?(Entity.idt, Component.idt, [Component.t] | nil) ::
    {true, owns_component_relay}
    | owns_component_error
  @doc """
  Henforces the Entity is the owner of the given component. The third parameter,
  `owned`, allows users of this function to pass a previously fetched list of
  components owned by the entity (cache).
  """
  def owns_component?(entity_id = %Entity.ID{}, component, owned) do
    henforce entity_exists?(entity_id) do
      owns_component?(relay.entity, component, owned)
    end
  end

  def owns_component?(entity, component_id = %Component.ID{}, owned) do
    henforce(ComponentHenforcer.component_exists?(component_id)) do
      owns_component?(entity, relay.component, owned)
    end
  end

  def owns_component?(entity = %Entity{}, component = %Component{}, nil) do
    owned_components =
      entity
      |> EntityQuery.get_components()
      |> Enum.map(&(ComponentQuery.fetch(&1.component_id)))

    owns_component?(entity, component, owned_components)
  end

  def owns_component?(entity = %Entity{}, component = %Component{}, owned) do
    if component in owned do
      reply_ok()
    else
      reply_error({:component, :not_belongs})
    end
    |> wrap_relay(
      %{entity: entity, component: component, owned_components: owned}
    )
  end

  @type owns_nip_relay ::
    %{
      network_connection: Network.Connection.t,
      entity: Entity.t,
      entity_network_connections: [Network.Connection.t]
    }
  @type owns_nip_relay_partial ::
    %{
      entity: Entity.t,
      entity_network_connections: [Network.Connection.t]
    }
  @type owns_nip_error ::
    {false, {:network_connection, :not_belongs}, owns_nip_relay_partial}
    | entity_exists_error

  @typep owned_ncs :: [Network.Connection.t] | nil

  @spec owns_nip?(Entity.idt, Network.id, Network.ip, owned_ncs) ::
    {true, owns_nip_relay}
    | owns_nip_error
  @doc """
  Henforces the Entity is the owner of the given NIP (NetworkConnection). The
  third parameter, `owned`, allows users of this function to pass a previously
  fetched list of NCs owned by the entity (cache).
  """
  def owns_nip?(entity_id = %Entity.ID{}, network_id, ip, owned) do
    henforce entity_exists?(entity_id) do
      owns_nip?(relay.entity, network_id, ip, owned)
    end
  end

  def owns_nip?(entity = %Entity{}, network_id, ip, nil) do
    owned_nips = NetworkQuery.Connection.get_by_entity(entity.entity_id)

    owns_nip?(entity, network_id, ip, owned_nips)
  end

  def owns_nip?(entity = %Entity{}, network_id, ip, owned) do
    nc = Enum.find(owned, &(&1.network_id == network_id and &1.ip == ip))

    if nc do
      reply_ok(%{network_connection: nc})
    else
      reply_error({:network_connection, :not_belongs})
    end
    |> wrap_relay(%{entity_network_connections: owned, entity: entity})
  end

  @type owns_storage_relay :: %{entity: Entity.t, storage: Storage.t}
  @type owns_storage_relay_partial :: map
  @type owns_storage_error ::
    {false, {:storage, :not_belongs}, owns_storage_relay_partial}
    | entity_exists_error
    | StorageHenforcer.storage_exists_error

  @spec owns_storage?(Entity.idt, Storage.idt) ::
    {true, owns_storage_relay}
    | owns_storage_error
  @doc """
  Henforces the Entity is the owner of the given Storage.
  """
  def owns_storage?(entity_id = %Entity.ID{}, storage) do
    henforce entity_exists?(entity_id) do
      owns_storage?(relay.entity, storage)
    end
  end

  def owns_storage?(entity, storage_id = %Storage.ID{}) do
    henforce StorageHenforcer.storage_exists?(storage_id) do
      owns_storage?(entity, relay.storage)
    end
  end

  def owns_storage?(entity = %Entity{}, storage = %Storage{}) do
    {:ok, server_id} = CacheQuery.from_storage_get_server(storage)

    henforce_else(owns_server?(entity, server_id), {:storage, :not_belongs})
    |> wrap_relay(%{entity: entity, storage: storage})
  end

  @type owns_bounce_relay :: %{entity: Entity.t, bounce: Bounce.t}
  @type owns_bounce_relay_partial :: map
  @type owns_bounce_error ::
    {false, {:bounce, :not_belongs}, owns_bounce_relay_partial}
    | entity_exists_error
    | BounceHenforcer.bounce_exists_error

  @spec owns_bounce?(Entity.idt, Bounce.idt) ::
    {true, owns_bounce_relay}
    | owns_bounce_error
  @doc """
  Henforces the Entity is the owner of the given Bounce.
  """
  def owns_bounce?(entity_id = %Entity.ID{}, bounce) do
    henforce entity_exists?(entity_id) do
      owns_bounce?(relay.entity, bounce)
    end
  end

  def owns_bounce?(entity, bounce_id = %Bounce.ID{}) do
    henforce BounceHenforcer.bounce_exists?(bounce_id) do
      owns_bounce?(entity, relay.bounce)
    end
  end

  def owns_bounce?(entity = %Entity{}, bounce = %Bounce{}) do
    if bounce.entity_id == entity.entity_id do
      reply_ok()
    else
      reply_error({:bounce, :not_belongs})
    end
    |> wrap_relay(%{entity: entity, bounce: bounce})
  end

  @type owns_virus_relay :: %{entity: Entity.t, virus: Virus.t}
  @type owns_virus_relay_partial :: map
  @type owns_virus_error ::
    {false, {:virus, :not_belongs}, owns_virus_relay_partial}
    | entity_exists_error
    | VirusHenforcer.virus_exists_error

  @spec owns_virus?(Entity.idt, File.idt | Virus.t) ::
    {true, owns_virus_relay}
    | owns_virus_error
  @doc """
  Henforces the Entity is the owner (installed) the given virus.
  """
  def owns_virus?(entity_id = %Entity.ID{}, virus) do
    henforce entity_exists?(entity_id) do
      owns_virus?(relay.entity, virus)
    end
  end

  def owns_virus?(entity, virus_id = %File.ID{}) do
    henforce VirusHenforcer.virus_exists?(virus_id) do
      owns_virus?(entity, relay.virus)
    end
  end

  def owns_virus?(entity, virus = %File{}) do
    henforce VirusHenforcer.virus_exists?(virus.file_id) do
      owns_virus?(entity, relay.virus)
    end
  end

  def owns_virus?(entity = %Entity{}, virus = %Virus{}) do
    if virus.entity_id == entity.entity_id do
      reply_ok()
    else
      reply_error({:virus, :not_belongs})
    end
    |> wrap_relay(%{entity: entity, virus: virus})
  end

  @type owns_bank_account_relay ::
    %{entity: Entity.t, bank_account: BankAccount.t}
  @type owns_bank_account_relay_partial :: map
  @type owns_bank_account_error ::
    {false, {:bank_account, :not_belongs}, owns_bank_account_relay_partial}
    | entity_exists_error

  @spec owns_bank_account?(Entity.idt, BankAccount.t) ::
    {true, owns_bank_account_relay}
    | owns_bank_account_error
  @doc """
  Henforces the Entity is the owner of the given bank account.
  """
  def owns_bank_account?(entity_id = %Entity.ID{}, bank_account) do
    henforce entity_exists?(entity_id) do
      owns_bank_account?(relay.entity, bank_account)
    end
  end

  def owns_bank_account?(entity = %Entity{}, bank_account = %BankAccount{}) do
    # TODO #260
    if to_string(entity.entity_id) == to_string(bank_account.owner_id) do
      reply_ok()
    else
      reply_error({:bank_account, :not_belongs})
    end
    |> wrap_relay(%{entity: entity, bank_account: bank_account})
  end
end
