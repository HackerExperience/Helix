defmodule Helix.Universe.Bank.Internal.BankTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID

  alias Helix.Universe.Bank.Internal.Bank, as: BankInternal

  alias HELL.TestHelper.Random
  alias Helix.Test.Universe.NPC.Setup, as: NPCSetup
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper

  describe "create/1" do
    test "creates when params are valid" do
      npc = NPCSetup.npc()

      params = %{
        bank_id: npc.npc_id,
        name: "BancoPelado"
      }

      assert {:ok, _} = BankInternal.create(params)
    end

    test "refuses to create when data is invalid" do
      params = %{bank_id: Random.pk(), name: "asdf"}
      assert_raise Ecto.ConstraintError, fn ->
        BankInternal.create(params)
      end
    end
  end

  describe "fetch/1" do
    test "fetches with valid data" do
      {bank, _} = NPCHelper.bank()

      entry = BankInternal.fetch(bank.id)
      assert entry
      assert_id entry.bank_id, bank.id
    end
  end
end
