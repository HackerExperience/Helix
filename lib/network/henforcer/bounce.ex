defmodule Helix.Network.Henforcer.Bounce do

  import Helix.Henforcer

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network

  @typep entry ::
    %{network_id: Network.id, ip: Network.ip, password: Server.password}

  @type can_create_bounce_relay :: has_access_entries_relay
  @type can_create_bounce_error :: has_access_entries_error

  @spec can_create_bounce?(Entity.id, Bounce.name, [entry]) ::
    {true, can_create_bounce_relay}
    | can_create_bounce_error
  @doc """
  Verifies whether `entity_id` may create a new bounce of name `name` with the
  given `entries`.
  """
  def can_create_bounce?(_entity_id, _name, entries) do
    henforce has_access_entries?(entries) do
      reply_ok(relay)
    end
  end

  @type has_access_entries_relay :: %{servers: [Server.t]}
  @type has_access_entries_relay_partial :: %{}
  @type has_access_entries_error ::
    {false, {:bounce, :no_access}, has_access_entries_relay_partial}

  @spec has_access_entries?([entry]) ::
    {true, has_access_entries_relay}
    | has_access_entries_error
  @doc """
  Verifies whether there's access to all servers listed on `entries`
  """
  def has_access_entries?(entries) do
    entries
    |> Enum.reduce(%{servers: []}, fn entry, acc ->
      if is_map(acc) do
        case has_access?(entry.network_id, entry.ip, entry.password) do
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
