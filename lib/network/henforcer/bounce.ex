defmodule Helix.Network.Henforcer.Bounce do

  import Helix.Henforcer

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Bounce, as: BounceQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Network.Websocket.Requests.Bounce.Utils, as: BounceRequestUtils

  @typep link :: BounceRequestUtils.link

  @type bounce_exists_relay :: %{bounce: Bounce.t}
  @type bounce_exists_relay_partial :: %{}
  @type bounce_exists_error ::
    {false, {:bounce, :not_found}, bounce_exists_relay_partial}

  @spec bounce_exists?(Bounce.id) ::
    {true, bounce_exists_relay}
    | bounce_exists_error
  @doc """
  Henforces that the given bounce exists.
  """
  def bounce_exists?(bounce_id = %Bounce.ID{}) do
    with bounce = %Bounce{} <- BounceQuery.fetch(bounce_id) do
      reply_ok(%{bounce: bounce})
    else
      _ ->
        reply_error({:bounce, :not_found})
    end
  end

  @type can_create_bounce_relay :: has_access_links_relay
  @type can_create_bounce_error :: has_access_links_error

  @spec can_create_bounce?(Entity.id, Bounce.name, [link]) ::
    {true, can_create_bounce_relay}
    | can_create_bounce_error
  @doc """
  Verifies whether `entity_id` may create a new bounce of name `name` with the
  given `links`.
  """
  def can_create_bounce?(_entity_id, _name, links) do
    henforce has_access_links?(links) do
      reply_ok(relay)
    end
  end

  @type can_update_bounce_relay ::
    %{servers: [Server.t], entity: Entity.t, bounce: Bounce.t}
  @type can_update_bounce_relay_partial :: map
  @type can_update_bounce_error ::
    EntityHenforcer.owns_bounce_error
    | bounce_not_in_use_error
    | has_access_links_error

  @doc """
  Henforces that `entity_is` is allowed to update `bounce_id` with the
  `new_name` and the `new_links`.
  """
  def can_update_bounce?(entity_id, bounce_id, _new_name, new_links) do
    base_henforcer = fn ->
      with {true, r1} <- EntityHenforcer.owns_bounce?(entity_id, bounce_id) do
        reply_ok(r1)
      end
    end

    link_change_henforcer = fn bounce ->
      with \
        {true, r1} <- bounce_not_in_use?(bounce),
        {true, r2} <- has_access_links?(new_links)
      do
        reply_ok(relay(r1, r2))
      end
    end

    with \
      {true, r1} <- base_henforcer.(),
      bounce = r1.bounce,
      {true, r2} <- link_change_henforcer.(bounce)
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type can_remove_bounce_relay :: %{entity: Entity.t, bounce: Bounce.t}
  @type can_remove_bounce_relay_partial :: %{}
  @type can_remove_bounce_error ::
    EntityHenforcer.owns_bounce_error
    | bounce_not_in_use_error

  @spec can_remove_bounce?(Entity.id, Bounce.id) ::
    {true, can_remove_bounce_relay}
    | can_remove_bounce_error
  @doc """
  Henforces that `entity_id` is allowed to remove `bounce_id`.
  """
  def can_remove_bounce?(entity_id, bounce_id) do
    with \
      {true, r1} <- EntityHenforcer.owns_bounce?(entity_id, bounce_id),
      bounce = r1.bounce,
      {true, r2} <- bounce_not_in_use?(bounce)
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type can_use_bounce_relay :: EntityHenforcer.owns_bounce_relay
  @type can_use_bounce_relay_partial :: map
  @type can_use_bounce_error :: EntityHenforcer.owns_bounce_error

  @spec can_use_bounce?(Entity.idt, Bounce.id | nil) ::
    {true, can_use_bounce_relay}
    | can_use_bounce_error
  @doc """
  Henforces that `entity` is allowed to use `bounce_id`.

  All one entity has to do in order to use the bounce is to be its owner. If no
  bounce is specified, the entity can always use it. (The bounce identified as
  `nil` has this special meaning).
  """
  def can_use_bounce?(_entity_id, nil),
    do: {true, %{bounce: nil}}
  def can_use_bounce?(entity, bounce_id),
    do: EntityHenforcer.owns_bounce?(entity, bounce_id)

  @type has_access_links_relay :: %{servers: [Server.t]}
  @type has_access_links_relay_partial :: %{}
  @type has_access_links_error ::
    {false, {:bounce, :no_access}, has_access_links_relay_partial}

  @spec has_access_links?([link]) ::
    {true, has_access_links_relay}
    | has_access_links_error
  @doc """
  Verifies whether there's access to all servers listed on `links`
  """
  def has_access_links?(links) do
    links
    |> Enum.reduce(%{servers: []}, fn link, acc ->
      if is_map(acc) do
        case has_access?(link.network_id, link.ip, link.password) do
          {true, relay} ->
            %{servers: acc.servers ++ [relay.server]}

          {false, reason, _} ->
            reason
        end
      else
        acc
      end
    end)
    |> case do
        relay = %{servers: _} ->
          reply_ok(relay)

        reason = {_, _} ->
          reply_error(reason)
      end
  end

  @type has_access_relay :: %{server: Server.t}
  @type has_access_relay_partial :: %{}
  @type has_access_error ::
    {false, {:bounce, :no_access}, has_access_relay_partial}
    | NetworkHenforcer.nip_exists_error

  @spec has_access?(Network.id, Network.ip, Server.password) ::
    {true, has_access_relay}
    | has_access_error
  @doc """
  Verifies whether access should be granted to the given {`network_id`, `ip`}
  based on the given `password`.
  """
  def has_access?(network_id, ip, password) do
    with \
      {true, r1} <- NetworkHenforcer.nip_exists?(network_id, ip),
      server = r1.server,
      {true, _} <-
        henforce_else(
          ServerHenforcer.password_valid?(server, password),
          {:bounce, :no_access}
        )
    do
      reply_ok(%{server: server})
    end
  end

  @type bounce_in_use_relay :: %{bounce: Bounce.t}
  @type bounce_in_use_relay_partial :: bounce_in_use_relay
  @type bounce_in_use_error ::
    {false, {:bounce, :not_in_use}, bounce_in_use_relay_partial}
    | bounce_exists_error

  @spec bounce_in_use?(Bounce.idt) ::
    {true, bounce_in_use_relay}
    | bounce_in_use_error
  @doc """
  Henforces that the given bounce is being used.
  """
  def bounce_in_use?(bounce_id = %Bounce.ID{}) do
    henforce bounce_exists?(bounce_id) do
      bounce_in_use?(relay.bounce)
    end
  end

  def bounce_in_use?(bounce = %Bounce{}) do
    case TunnelQuery.get_tunnels_on_bounce(bounce.bounce_id) do
      [_] ->
        reply_ok()

      [] ->
        reply_error({:bounce, :not_in_use})
    end
    |> wrap_relay(%{bounce: bounce})
  end

  @type bounce_not_in_use_relay :: bounce_in_use_relay_partial
  @type bounce_not_in_use_relay_partial :: bounce_in_use_relay
  @type bounce_not_in_use_error ::
    {false, {:bounce, :in_use}, bounce_not_in_use_relay_partial}
    | bounce_exists_error

  @spec bounce_not_in_use?(Bounce.idt) ::
    {true, bounce_not_in_use_relay}
    | bounce_not_in_use_error
  @doc """
  Henforces that the given bounce is NOT being used.
  """
  def bounce_not_in_use?(bounce),
    do: henforce_not(bounce_in_use?(bounce), {:bounce, :in_use})
end
