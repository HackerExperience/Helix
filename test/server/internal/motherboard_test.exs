defmodule Helix.Server.Internal.MotherboardTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Model.Network
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Model.Component

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup

  @internet_id NetworkHelper.internet_id()

  describe "fetch/1" do
    test "fetches and formats the result" do
      {gen_motherboard, %{mobo: mobo, hdd: hdd}} = ComponentSetup.motherboard()

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      assert motherboard == gen_motherboard

      # Ran `Component.format`
      assert motherboard.slots.hdd_1.custom.iops == hdd.custom.iops
    end

    test "returns nil if not found" do
      refute MotherboardInternal.fetch(Component.ID.generate())
    end
  end

  describe "fetch_by_component/1" do
    test "fetches and formats the result" do
      {gen_motherboard, %{hdd: hdd}} = ComponentSetup.motherboard()

      motherboard = MotherboardInternal.fetch_by_component(hdd.component_id)

      assert motherboard == gen_motherboard
    end

    test "returns nil if not found" do
      refute MotherboardInternal.fetch_by_component(Component.ID.generate())
    end
  end

  describe "get_resources/1" do
    test "returns all resources" do
      {_, components = %{mobo: mobo}} =
        ComponentSetup.motherboard(
          spec_id: :mobo_999, nic_opts: [ulk: 30, dlk: 60]
        )

      motherboard = MotherboardInternal.fetch(mobo.component_id)
      res = MotherboardInternal.get_resources(motherboard)

      assert res.cpu.clock == components.cpu.custom.clock
      assert res.hdd.size == components.hdd.custom.size
      assert res.hdd.iops == components.hdd.custom.iops
      assert res.net[@internet_id].dlk == components.nic.custom.dlk
      assert res.net[@internet_id].ulk == components.nic.custom.ulk

      # We'll link an extra component of each to make sure the function updates
      # the total resources accordingly
      {cpu, _} = ComponentSetup.component(type: :cpu)
      {hdd, _} = ComponentSetup.component(type: :hdd)
      {ram, _} = ComponentSetup.component(type: :ram)
      {nic, _} = ComponentSetup.nic(ulk: 20, dlk: 21, network_id: @internet_id)

      assert {:ok, _} = MotherboardInternal.link(motherboard, mobo, cpu, :cpu_2)
      assert {:ok, _} = MotherboardInternal.link(motherboard, mobo, hdd, :hdd_2)
      assert {:ok, _} = MotherboardInternal.link(motherboard, mobo, nic, :nic_2)
      assert {:ok, _} = MotherboardInternal.link(motherboard, mobo, ram, :ram_2)

      motherboard = MotherboardInternal.fetch(mobo.component_id)
      new_res = MotherboardInternal.get_resources(motherboard)

      # It returned the updated resources
      refute new_res == res

      assert new_res.cpu.clock == components.cpu.custom.clock + cpu.custom.clock
      assert new_res.hdd.size == components.hdd.custom.size + hdd.custom.size
      assert new_res.hdd.iops == components.hdd.custom.iops + hdd.custom.iops
      assert new_res.ram.clock == components.ram.custom.clock + ram.custom.clock
      assert new_res.ram.size == components.ram.custom.size + ram.custom.size
      assert new_res.net[@internet_id].dlk == 60 + 21
      assert new_res.net[@internet_id].ulk == 30 + 20

      # Now we'll add yet another NIC, but with a different network
      net2 = "::f" |> Network.ID.cast!()
      {nic2, _} = ComponentSetup.nic(dlk: 1, ulk: 2, network_id: net2)

      MotherboardInternal.link(motherboard, mobo, nic2, :nic_3)

      # Let's fetch again...
      motherboard = MotherboardInternal.fetch(mobo.component_id)
      new_res = MotherboardInternal.get_resources(motherboard)

      # Added the new network to the total mobo resources
      assert new_res.net[net2].dlk == 1
      assert new_res.net[net2].ulk == 2

      # Previous network resources (internet) remain unchanged
      assert new_res.net[@internet_id].dlk == 60 + 21
      assert new_res.net[@internet_id].ulk == 30 + 20
    end
  end

  describe "setup/2" do
    test "inserts the mobo and all its components" do
      # Let's create all the required components first
      {mobo, _} = ComponentSetup.component(type: :mobo)
      {cpu, _} = ComponentSetup.component(type: :cpu)
      {ram, _} = ComponentSetup.component(type: :ram)
      {hdd, _} = ComponentSetup.component(type: :hdd)
      {nic, _} = ComponentSetup.component(type: :nic)

      assert mobo.type == :mobo
      assert cpu.type == :cpu
      assert hdd.type == :hdd
      assert nic.type == :nic
      assert ram.type == :ram

      initial_components =
        [
          {cpu, :cpu_1},
          {hdd, :hdd_1},
          {nic, :nic_1},
          {ram, :ram_1}
        ]

      assert {:ok, motherboard} =
        MotherboardInternal.setup(mobo, initial_components)

      assert motherboard.motherboard_id == mobo.component_id

      Enum.each(motherboard.slots, fn {slot_id, component} ->
        case slot_id do
          :cpu_1 ->
            assert component.component_id == cpu.component_id

          :hdd_1 ->
            assert component.component_id == hdd.component_id

          :nic_1 ->
            assert component.component_id == nic.component_id

          :ram_1 ->
            assert component.component_id == ram.component_id
        end
      end)
    end

    test "rejects components linked on wrong/invalid slot" do
      %{
        mobo: mobo,
        cpu: cpu,
        hdd: hdd,
        ram: ram,
        nic: nic
      } = ComponentSetup.mobo_components()

      i0 = [{hdd, :cpu_1}, {cpu, :hdd_1}, {nic, :nic_1}, {ram, :ram_1}]
      i1 = [{cpu, :cpu_1}, {hdd, :hdd_9}, {nic, :nic_1}, {ram, :ram_1}]

      assert {:error, reason} = MotherboardInternal.setup(mobo, i0)
      assert reason == :wrong_slot_type

      assert {:error, reason} = MotherboardInternal.setup(mobo, i1)
      assert reason == :bad_slot
    end

    test "requires that all basic components are present" do
      %{mobo: mobo, cpu: cpu} = ComponentSetup.mobo_components()

      # Missing hdd, ram, nic...
      initial_components = [{cpu, :cpu_1}]

      assert {:error, reason} =
        MotherboardInternal.setup(mobo, initial_components)
      assert reason == :missing_initial_components
    end

    test "cant link a mobo onto another mobo (that would be cool though)" do
      %{
        mobo: mobo,
        cpu: _cpu,
        hdd: hdd,
        nic: nic,
        ram: ram
      } = ComponentSetup.mobo_components()

      initial_components =
        [
          {mobo, :cpu_1},
          {hdd, :hdd_1},
          {nic, :nic_1},
          {ram, :ram_1}
        ]

      assert {:error, reason} =
        MotherboardInternal.setup(mobo, initial_components)
      assert reason == :missing_initial_components
    end
  end

  describe "link/4" do
    test "links a component to a mobo" do
      {_, %{mobo: mobo}} = ComponentSetup.motherboard(spec_id: :mobo_002)
      {cpu, _} = ComponentSetup.component(type: :cpu)

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      assert {:ok, entry} =
        MotherboardInternal.link(motherboard, mobo, cpu, :cpu_2)

      assert entry.motherboard_id == mobo.component_id
      assert entry.linked_component_id == cpu.component_id
      assert entry.slot_id == :cpu_2

      new_motherboard = MotherboardInternal.fetch(mobo.component_id)

      refute motherboard == new_motherboard

      # The new motherboard has one extra component attached to it
      assert length(new_motherboard.slots |> Map.to_list()) ==
        length(motherboard.slots |> Map.to_list()) + 1
    end

    test "wont link to a slot that is wrong or invalid" do
      {_, %{mobo: mobo}} = ComponentSetup.motherboard()
      {cpu, _} = ComponentSetup.component(type: :cpu)

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      assert {:error, reason} =
        MotherboardInternal.link(motherboard, mobo, cpu, :cpu_999)
      assert reason == :bad_slot

      assert {:error, reason} =
        MotherboardInternal.link(motherboard, mobo, cpu, :ram_1)
      assert reason == :wrong_slot_type
    end

    test "wont link to a slot that is already in use" do
      {_, %{mobo: mobo}} = ComponentSetup.motherboard()
      {cpu, _} = ComponentSetup.component(type: :cpu)

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      assert {:error, reason} =
        MotherboardInternal.link(motherboard, mobo, cpu, :cpu_1)
      assert reason == :slot_in_use
    end
  end

  describe "unlink/2" do
    test "unlinks the component from the mobo" do
      # Note: disassembling the last "essential" component would take the server
      # offline or maybe be a forbidden operation, but that happens at a higher
      # level (not at the Internal level).
      {_, %{mobo: mobo, hdd: hdd}} = ComponentSetup.motherboard()

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      MotherboardInternal.unlink(hdd)

      new_motherboard = MotherboardInternal.fetch(mobo.component_id)

      refute motherboard == new_motherboard
      refute Map.has_key?(new_motherboard.slots, :hdd_1)

      # The new motherboard has one less component attached to it
      assert length(new_motherboard.slots |> Map.to_list()) ==
        length(motherboard.slots |> Map.to_list()) - 1
    end

    test "performs a noop if the component is not linked" do
      {_, %{mobo: mobo}} = ComponentSetup.motherboard()
      {component, _} = ComponentSetup.component()

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      MotherboardInternal.unlink(component)

      new_motherboard = MotherboardInternal.fetch(mobo.component_id)

      assert motherboard == new_motherboard
    end
  end
end
