defmodule Helix.Software.Model.Software.Cracker.BruteforceTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Process.Public.View.Process, as: ProcessView
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Software.Cracker.Bruteforce, as: CrackerBruteforce

  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.View.Helper, as: ProcessViewHelper
  alias Helix.Test.Software.Factory, as: SoftwareFactory

  # FIXME: this will be removed when file modules become just an attribute
  @cracker_file (
    :file
    |> SoftwareFactory.build(software_type: :cracker)
    |> Map.update!(:file_modules, fn xs ->
      xs
      |> Enum.map(&({&1.software_module, &1.module_version}))
      |> :maps.from_list()
    end))

  describe "create/2" do
    test "returns changeset if invalid" do
      assert {:error, changeset} = CrackerBruteforce.create(@cracker_file, %{})
      assert %Changeset{valid?: false} = changeset
    end

    # REVIEW: Why cracker isn't using file_id?
    @required_fields ~w/
      network_id
      target_server_id
      target_server_ip/a
    @field_names @required_fields |> Enum.map(&to_string/1) |> Enum.join(", ")
    test "requires #{@field_names}" do
      assert {:error, changeset} = CrackerBruteforce.create(@cracker_file, %{})
      errors = Keyword.keys(changeset.errors)
      assert Enum.sort(@required_fields) == Enum.sort(errors)
    end
  end

  describe "objective/1" do
    test "returns a higher objective the higher the firewall version is" do
      cracker = %CrackerBruteforce{
        network_id: Network.ID.generate(),
        target_server_id: Server.ID.generate(),
        target_server_ip: IPv4.autogenerate(),
        software_version: 100
      }

      obj1 = CrackerBruteforce.objective(cracker, 100)
      obj2 = CrackerBruteforce.objective(cracker, 200)
      obj3 = CrackerBruteforce.objective(cracker, 300)
      obj4 = CrackerBruteforce.objective(cracker, 900)

      assert obj2 > obj1
      assert obj3 > obj2
      assert obj4 > obj3
    end

    test "returns a lower objective the higher the cracker version is" do
      cracker = %CrackerBruteforce{
        network_id: Network.ID.generate(),
        target_server_id: Server.ID.generate(),
        target_server_ip: IPv4.autogenerate(),
        software_version: 100
      }

      obj1 = CrackerBruteforce.objective(cracker, 900)
      obj2 = CrackerBruteforce.objective(%{cracker| software_version: 200}, 900)
      obj3 = CrackerBruteforce.objective(%{cracker| software_version: 300}, 900)
      obj4 = CrackerBruteforce.objective(%{cracker| software_version: 900}, 900)

      assert obj2 < obj1
      assert obj3 < obj2
      assert obj4 < obj3
    end
  end

  describe "ProcessView.render/4" do
    test "full process for any AT attack_source" do
      {process, meta} =
        ProcessSetup.process(fake_server: true, type: :bruteforce)
      data = process.process_data
      server_id = process.gateway_id

      attacker_id = meta.source_entity_id
      victim_id = meta.target_entity_id
      third_id = Entity.ID.generate()

      # Here we cover all possible cases on `attack_source`, so regardless of
      # *who* is listing the processes, as long as it's on the `attack_source`,
      # they have full access to the process.
      pview_attacker = ProcessView.render(data, process, server_id, attacker_id)
      pview_victim = ProcessView.render(data, process, server_id, victim_id)
      pview_third = ProcessView.render(data, process, server_id, third_id)

      full_process = pview_full()

      assert full_process == Enum.sort(Map.keys(pview_attacker))
      assert full_process == Enum.sort(Map.keys(pview_victim))
      assert full_process == Enum.sort(Map.keys(pview_third))
    end

    test "full process for attacker AT attack_target" do
      {process, %{source_entity_id: entity_id}} =
        ProcessSetup.process(fake_server: true, type: :bruteforce)
      data = process.process_data
      server_id = process.target_server_id

      # `entity` is the one who started the process, and is listing at the
      # victim server, so `entity` has full access to the process.
      rendered = ProcessView.render(data, process, server_id, entity_id)

      keys = Map.keys(rendered)
      expected = pview_full()

      assert expected == Enum.sort(keys)
    end

    test "partial process for third AT attack_target" do
      {process, _} = ProcessSetup.process(fake_server: true, type: :bruteforce)
      data = process.process_data
      server_id = process.target_server_id
      entity_id = Entity.ID.generate()

      # `entity` is unrelated to the process, and it's being rendering on the
      # receiving end of the process (victim), so partial access is applied.
      rendered = ProcessView.render(data, process, server_id, entity_id)

      keys = Map.keys(rendered)
      expected = pview_partial()

      assert expected == Enum.sort(keys)
    end

    test "partial process for victim AT attack_target" do
      {process, %{target_entity_id: entity_id}} =
        ProcessSetup.process(fake_server: true, type: :bruteforce)
      data = process.process_data
      server_id = process.target_server_id

      # `entity` is the victim, owner of the server receiving the process.
      # She's rendering at her own server, but she did not start the process,
      # so she has limited access to the process.
      rendered = ProcessView.render(data, process, server_id, entity_id)

      keys = Map.keys(rendered)
      expected = pview_partial()

      assert expected == Enum.sort(keys)
    end

    defp pview_full do
      ProcessViewHelper.pview_full()
      |> Kernel.++(~w/software_version target_server_ip/a)
      |> Enum.sort()
    end
    defp pview_partial do
      ProcessViewHelper.pview_partial()
      |> Kernel.++(~w/software_version target_server_ip/a)
      |> Enum.sort()
    end
  end
end
