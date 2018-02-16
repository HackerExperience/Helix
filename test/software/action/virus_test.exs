defmodule Helix.Software.Action.VirusTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Action.Virus, as: VirusAction
  alias Helix.Software.Model.Virus
  alias Helix.Software.Query.Virus, as: VirusQuery

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "collect/2" do
    test "collects earnings of the virus" do
      {virus = %{entity_id: entity_id}, %{file: file}} =
        SoftwareSetup.Virus.virus(type: :virus_spyware, running_time: 600)

      # Virus has been running for 10 minutes
      assert virus.running_time == 600

      # And it's expected to earn something
      expected_earnings = Virus.calculate_earnings(file, virus, [])
      assert expected_earnings > 0

      bank_acc = BankSetup.fake_account!(owner_id: entity_id)
      payment_info = {bank_acc, nil}

      # Collect the rewards
      assert {:ok, [virus_collected]} = VirusAction.collect(file, payment_info)

      # Virus event is correct
      assert virus_collected.virus.file_id == file.file_id
      assert virus_collected.virus.entity_id == entity_id
      assert virus_collected.earnings == expected_earnings
      assert virus_collected.bank_account == bank_acc
      refute virus_collected.wallet

      # Now let's test the side-effects...
      virus2 = VirusQuery.fetch(file.file_id)

      # The virus is still active, but had its running time set to 0
      assert virus2.running_time == 0
      assert virus2.is_active?
    end
  end
end
