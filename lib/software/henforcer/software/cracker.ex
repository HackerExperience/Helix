defmodule Helix.Software.Henforcer.Software.Cracker do

  import Helix.Henforcer

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Software.Henforcer.File, as: FileHenforcer

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

  def exists_cracker?(module, server) do
    henforce_else(
      FileHenforcer.exists_software_module?(module, server),
      {:cracker, :not_found}
    )
  end
end
