defmodule Helix.Software.Model.Software.CrackerTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Process.Public.View.Process, as: ProcessView
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Software.Cracker.Bruteforce, as: CrackerBruteforce

  alias Helix.Test.Process.Factory, as: ProcessFactory
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
      source_entity_id
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
        source_entity_id: Entity.ID.generate(),
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
        source_entity_id: Entity.ID.generate(),
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
    test "returns software_version and target_server_ip" do
      process = process_to_render()
      data = process.process_data
      server = process.gateway_id
      entity = Entity.ID.generate()

      version = data.software_version
      ip = data.target_server_ip

      rendered = ProcessView.render(data, process, server, entity)

      assert version == rendered.software_version
      assert ip == rendered.target_server_ip
    end

    test "returns a map on remote" do
      process = process_to_render()
      data = process.process_data
      server = Server.ID.generate()
      entity = Entity.ID.generate()

      rendered = ProcessView.render(data, process, server, entity)

      keys = Map.keys(rendered)
      expected = ~w/
        process_id
        gateway_id
        target_server_id
        file_id
        network_id
        connection_id
        process_type
        software_version
        target_server_ip/a

      assert Enum.sort(expected) == Enum.sort(keys)
    end

    test "returns a map on local" do
      process = process_to_render()
      data = process.process_data
      server = process.gateway_id
      entity = Entity.ID.generate()

      rendered = ProcessView.render(data, process, server, entity)

      keys = Map.keys(rendered)
      expected = ~w/
        process_id
        gateway_id
        target_server_id
        file_id
        network_id
        connection_id
        process_type
        state
        allocated
        priority
        creation_time
        software_version
        target_server_ip/a

      assert Enum.sort(expected) == Enum.sort(keys)
    end
  end

  # TODO: Use a helper or something like that to test rendered processes. It
  # will be unmaintainable to use the current test method for upcoming processes

  defp process_to_render do
    %{
      ProcessFactory.build(:process)|
        process_data: %CrackerBruteforce{
          source_entity_id: Entity.ID.generate(),
          network_id: Network.ID.generate(),
          target_server_id: Server.ID.generate(),
          target_server_ip: IPv4.autogenerate(),
          software_version: Enum.random(100..999)
        },
        process_type: "cracker_bruteforce"
    }
  end
end
