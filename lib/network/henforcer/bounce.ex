defmodule Helix.Network.Henforcer.Bounce do

  import Helix.Henforcer

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network

  @typep link ::
    %{network_id: Network.id, ip: Network.ip, password: Server.password}

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
end
