defmodule Helix.Software.Henforcer.Software.CrackerTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Software.Henforcer.Software.Cracker, as: CrackerHenforcer
  alias Helix.Software.Model.File

  alias HELL.TestHelper.Random
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @internet_id NetworkHelper.internet_id()

  describe "can_bruteforce?" do
    test "accepts only when everything is valid" do
      {gateway, %{entity: entity}} = ServerSetup.server()
      {target, _} = ServerSetup.server()

      entity_id = entity.entity_id
      gateway_id = gateway.server_id
      target_id = target.server_id

      # Can I bruteforce?
      assert {false, reason, _} =
        CrackerHenforcer.can_bruteforce?(
          entity_id, gateway_id, @internet_id, Random.ipv4()
        )

      # Ops, no one was found under that NIP
      assert reason == {:nip, :not_found}

      gateway_nip = ServerHelper.get_nip(gateway)

      # What if...
      assert {false, reason, _} =
        CrackerHenforcer.can_bruteforce?(
          entity_id, gateway_id, gateway_nip.network_id, gateway_nip.ip
        )

      # Nope
      assert reason == {:target, :self}

      target_nip = ServerHelper.get_nip(target)

      # How 'bout now?
      assert {false, reason, _} =
        CrackerHenforcer.can_bruteforce?(
          entity_id, gateway_id, target_nip.network_id, target_nip.ip
        )

      # Nope, I don't have a cracker
      assert reason == {:cracker, :not_found}

      {cracker, _} = SoftwareSetup.cracker(server_id: gateway.server_id)

      # Now we are good to go!
      assert {true, relay} =
        CrackerHenforcer.can_bruteforce?(
          entity_id, gateway_id, target_nip.network_id, target_nip.ip
        )

      assert relay.gateway == gateway
      assert relay.target == target
      assert relay.cracker == cracker
      assert relay.attacker == entity
      assert_relay relay, [:gateway, :target, :cracker, :attacker]
    end
  end

  describe "exists_cracker?/2" do
    test "rejects with custom message" do
      {server, _} = ServerSetup.server()

      assert {false, reason, _} =
        CrackerHenforcer.exists_cracker?(:bruteforce, server)
      assert reason == {:cracker, :not_found}
    end
  end
end
