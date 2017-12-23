defmodule Helix.Server.Henforcer.Component do

  import Helix.Henforcer

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  @internet_id NetworkQuery.internet().network_id

  @type component_exists_relay :: %{component: Component.t}
  @type component_exists_relay_partial :: %{}
  @type component_exists_error ::
    {false, {:component, :not_found}, component_exists_relay_partial}

  @spec component_exists?(Component.id) ::
    {true, component_exists_relay}
    | component_exists_error
  @doc """
  Henforces the requested component exists on the database.
  """
  def component_exists?(component_id = %Component.ID{}) do
    with component = %Component{} <- ComponentQuery.fetch(component_id) do
      reply_ok(%{component: component})
    else
      _ ->
        reply_error({:component, :not_found})
    end
  end

  @type is_motherboard_relay :: %{component: Component.t}
  @type is_motherboard_relay_partial :: %{}
  @type is_motherboard_error ::
    {false, {:component, :not_motherboard}, is_motherboard_relay_partial}
    | {false, {:motherboard, :not_attached}, is_motherboard_relay_partial}
    | component_exists_error

  @spec is_motherboard?(Component.idt | nil) ::
    {true, is_motherboard_relay}
    | is_motherboard_error
  @doc """
  Checks whether the given component is a motherboard. `nil` is a valid input
  when checking against the motherboard_id of a server.

  It does not return `Motherboard.t` as a relay!
  """
  def is_motherboard?(nil),
    do: reply_error({:motherboard, :not_attached})
  def is_motherboard?(component = %Component{type: :mobo}),
    do: reply_ok(%{component: component})
  def is_motherboard?(%Component{}),
    do: reply_error({:component, :not_motherboard})
  def is_motherboard?(component_id = %Component.ID{}) do
    henforce(component_exists?(component_id)) do
      is_motherboard?(relay.component)
    end
  end

  @type can_link_relay :: %{}
  @type can_link_error ::
    {false, {:motherboard, :wrong_slot_type | :slot_in_use | :bad_slot}, %{}}

  @spec can_link?(Component.mobo, Component.t, Motherboard.slot_id) ::
    {true, can_link_relay}
    | can_link_error
  @doc """
  Checks whether the given `component` can be linked to the `motherboard` at the
  given `slot_id`.
  """
  def can_link?(
    mobo = %Component{type: :mobo},
    component = %Component{},
    slot_id)
  do
    with :ok <- Motherboard.check_compatibility(mobo, component, slot_id, []) do
      reply_ok()
    else
      {:error, reason} ->
        reply_error({:motherboard, reason})
    end
  end

  @type has_initial_components_relay :: %{}
  @type has_initial_components_error ::
    {false, {:motherboard, :missing_initial_components}, %{}}

  @spec has_initial_components?([MotherboardAction.update_component]) ::
    {true, has_initial_components_relay}
    | has_initial_components_error
  @doc """
  Checks whether the given list of components, supposed to be linked to the
  motherboard, matches the minimum required components (`initial_components`).
  """
  def has_initial_components?(components) do
    if Motherboard.has_required_initial_components?(components) do
      reply_ok()
    else
      reply_error({:motherboard, :missing_initial_components})
    end
  end

  @type has_public_nip_relay :: %{}
  @type has_public_nip_error ::
    {false, {:motherboard, :missing_public_nip}, %{}}

  @spec has_public_nip?([Network.Connection.t]) ::
    {true, has_public_nip_relay}
    | has_public_nip_error
  @doc """
  Checks whether, among the specified NetworkConnection changes, at least one
  public NIP/NC is assigned to the motherboard.
  """
  def has_public_nip?(network_connections) do
    if Enum.find(network_connections, &(&1.network_id == @internet_id)) do
      reply_ok()
    else
      reply_error({:motherboard, :missing_public_nip})
    end
  end

  @type can_update_mobo_relay ::
    %{
      entity: Entity.t,
      mobo: Component.mobo,
      components: [MotherboardAction.update_component],
      owned_components: [Component.t],
      network_connections: [MotherboardAction.update_nc],
      entity_network_connections: [Network.Connection.t]
    }

  @type can_update_mobo_error ::
    component_exists_error
    | is_motherboard_error
    | can_link_error
    | has_initial_components_error
    | has_public_nip_error
    | EntityHenforcer.owns_component_error
    | EntityHenforcer.owns_nip_error

  @spec can_update_mobo?(
    Entity.id,
    Component.id,
    [MotherboardAction.update_component],
    [MotherboardAction.update_nc])
  ::
    {true, can_update_mobo_relay}
    | can_update_mobo_error
  @doc """
  Checks whether `entity` can update the `mobo_id` with the given components and
  network connections. It checks several underlying conditions, like if all
  components exist on the DB, as well as some game mechanics stuff like whether
  the mobo will have at least one public NIP assigned to it.
  """
  def can_update_mobo?(entity_id, mobo_id, components, network_connections) do
    reduce_components = fn mobo ->
      init = {{true, %{}}, nil}

      components
      |> Enum.reduce_while(init, fn {slot_id, comp_id}, {{true, acc}, cache} ->
        with \
          {true, r1} <- component_exists?(comp_id),
          component = r1.component,

          {true, r2} <-
            EntityHenforcer.owns_component?(entity_id, component, cache),

          {true, _} <- can_link?(mobo, component, slot_id)
        do
          acc_components = Map.get(acc, :components, [])

          new_acc =
            acc
            |> put_in([:components], acc_components ++ [{component, slot_id}])
            |> put_in([:entity], r2.entity)
            |> put_in([:owned_components], r2.owned_components)

          {:cont, {{true, new_acc}, r2.owned_components}}
        else
          error ->
            {:halt, {error, cache}}
        end
      end)
      |> elem(0)
    end

    reduce_network_connections = fn entity ->
      init = {{true, %{}}, nil}

      network_connections
      |> Enum.reduce_while(init, fn {nic_id, nip}, {{true, acc}, cache} ->
        {network_id, ip} = nip

        with \
          {true, r1} <- EntityHenforcer.owns_nip?(entity, network_id, ip, cache)
        do
          acc_nc = Map.get(acc, :network_connections, [])

          new_entry =
            %{
              nic_id: nic_id,
              network_id: network_id,
              ip: ip,
              network_connection: r1.network_connection
            }

          new_acc =
            acc
            |> put_in([:network_connections], acc_nc ++ [new_entry])
            |> put_in(
              [:entity_network_connections], r1.entity_network_connections
            )

          {:cont, {{true, new_acc}, r1.entity_network_connections}}
        else
          error ->
            {:halt, {error, cache}}
        end
      end)
      |> elem(0)
    end

    with \
      {true, r0} <- component_exists?(mobo_id),
      {r0, mobo} = get_and_replace(r0, :component, :mobo),

      # Make sure user is plugging components into a motherboard
      {true, _} <- is_motherboard?(mobo),

      # Iterate over components/slots and make the required henforcements
      {true, r1} <- reduce_components.(mobo),
      components = r1.components,
      entity = r1.entity,
      owned = r1.owned_components,

      # Ensure mobo belongs to entity
      {true, _} <- EntityHenforcer.owns_component?(entity, mobo, owned),

      # Ensure all required initial components are there
      {true, _} <- has_initial_components?(components),

      # Iterate over NetworkConnections and make the required henforcements
      {true, r2} <- reduce_network_connections.(entity),

      # The mobo must have at least one public NC assigned to it
      {true, _} <- has_public_nip?(r2.network_connections)
    do
      reply_ok(relay([r0, r1, r2]))
    else
      error ->
        error
    end
  end

  @type can_detach_mobo_relay ::
    %{
      server: Server.t,
      entity: Entity.t,
      mobo: Component.mobo,
      motherboard: Motherboard.t,
      owned_components: [Component.t]
    }

  @type can_detach_mobo_error ::
    component_exists_error
    | is_motherboard_error
    | ServerHenforcer.server_exists_error
    | EntityHenforcer.owns_component_error

  @spec can_detach_mobo?(Entity.id, Server.id) ::
    {true, can_detach_mobo_relay}
    | can_detach_mobo_error
  @doc """
  Ensures `entity_id` can detach mobo from `server_id`.
  """
  # TODO: Mainframe verification, cost analysis (for cooldown) etc. #358
  def can_detach_mobo?(entity_id, server_id) do
    with \
      {true, r0} <- ServerHenforcer.server_exists?(server_id),
      server = r0.server,

      # Server must have a motherboard attached to it...
      {true, _} <- is_motherboard?(server.motherboard_id),

      # Entity must be the owner of that motherboard
      {true, r1} <-
        EntityHenforcer.owns_component?(entity_id, server.motherboard_id, nil),
      r1 = replace(r1, :component, :mobo)
    do
      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      reply_ok(relay([r0, r1]))
      |> wrap_relay(%{motherboard: motherboard})
    end
  end
end
