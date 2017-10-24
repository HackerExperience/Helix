defmodule Helix.Software.Henforcer.Software.Cracker do

  import Helix.Henforcer

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Network.Model.Network
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Model.File

  @type can_bruteforce_relay ::
    %{gateway: Server.t, target: Server.t, cracker: File.t}
  @type can_bruteforce_relay_partial :: %{} | term  # TODO
  @type can_bruteforce_error ::
    {false, {:target, :self}, EntityHenforcer.owns_server_relay_partial}
    | term

  @spec can_bruteforce?(Entity.id, Server.id, Network.id, Network.ip) ::
    {true, can_bruteforce_relay}
    | can_bruteforce_error
  def can_bruteforce?(entity_id, gateway_id, network_id, target_ip) do
    with \
      {true, r1} <- ServerHenforcer.server_exists?(gateway_id),
      {r1, gateway} = get_and_replace(r1, :server, :gateway),
      {true, r2} <- NetworkHenforcer.nip_exists?(network_id, target_ip),
      {r2, target} = get_and_replace(r2, :server, :target),
      {true, r3} <- exists_cracker?(:bruteforce, gateway),
      r3 = replace(r3, :file, :cracker),
      {true, r4} <-
        henforce_not(
          EntityHenforcer.owns_server?(entity_id, target),
          {:target, :self}
        )
    do
      [r1, r2, r3, r4]
      |> relay()
      |> reply_ok()
    end
  end

  @type exists_cracker_relay :: FileHenforcer.exists_software_module_relay
  @type exists_cracker_relay_partial ::
    FileHenforcer.exists_software_module_relay_partial
  @type exists_cracker_error ::
    {false, {:cracker, :not_found}, exists_cracker_relay_partial}

  @spec exists_cracker?(File.Module.name, Server.t) ::
    {true, exists_cracker_relay}
    | exists_cracker_error
  def exists_cracker?(module, server) do
    henforce_else(
      FileHenforcer.exists_software_module?(module, server),
      {:cracker, :not_found}
    )
  end
end
