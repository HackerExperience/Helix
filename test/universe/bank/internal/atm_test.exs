defmodule Helix.Universe.Bank.Internal.ATMTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.IDCase

  alias HELL.TestHelper.Random
  alias HELL.TestHelper.Setup
  alias Helix.Universe.Bank.Internal.ATM, as: ATMInternal
  alias Helix.Universe.NPC.Helper, as: NPCHelper

  describe "create/1" do
    test "with valid data" do
      {server, _} = Setup.server()
      bank_id = NPCHelper.bank().id

      params = %{
        atm_id: server.server_id,
        bank_id: bank_id,
        region: "Braziu"
      }

      assert {:ok, atm} = ATMInternal.create(params)
      assert_id atm.atm_id, server.server_id
      assert_id atm.bank_id, bank_id
    end

    test "with invalid data" do
      params = %{atm_id: Random.pk(), bank_id: Random.pk(), region: "asdf"}
      assert_raise Ecto.ConstraintError, fn ->
        ATMInternal.create(params)
      end
    end
  end

  describe "fetch/1" do
    test "with valid data" do
      bank = NPCHelper.bank()
      atm = Enum.random(bank.servers)
      atm2 = ATMInternal.fetch(atm.id)

      assert atm2
      assert_id atm2.atm_id, atm.id
      assert atm2.region == atm.custom.region
    end
  end
end
