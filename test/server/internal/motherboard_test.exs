defmodule Helix.Server.Internal.MotherboardTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal

  alias Helix.Test.Server.Component.Setup, as: ComponentSetup

  describe "fetch/1" do
    test "fetches and formats the result" do
      {entries, %{mobo: mobo}} = ComponentSetup.motherboard()

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      assert motherboard.motherboard_id == mobo.component_id
      assert length(motherboard.slots |> Map.to_list()) == length(entries)

      # Ran `Component.format`
      assert motherboard.slots.hdd_0.custom.iops
    end
  end

  describe "setup/2" do
    test "inserts the mobo and all its components" do
      # Let's create all the required components first
      {mobo, _} = ComponentSetup.component(type: :mobo)
      {cpu, _} = ComponentSetup.component(type: :cpu)
      # {ram, _} = ComponentSetup.component(type: :ram)
      {hdd, _} = ComponentSetup.component(type: :hdd)

      assert mobo.type == :mobo
      assert cpu.type == :cpu
      assert hdd.type == :hdd

      initial_components =
        [
          {cpu, :cpu_0},
          {hdd, :hdd_0}
        ]

      assert {:ok, entries} =
        MotherboardInternal.setup(mobo, initial_components)

      Enum.each(entries, fn entry ->
        assert entry.motherboard_id == mobo.component_id

        case entry.slot_id do
          :cpu_0 ->
            assert entry.linked_component_id == cpu.component_id

          :hdd_0 ->
            assert entry.linked_component_id == hdd.component_id
        end
      end)
    end

    test "rejects components linked on wrong/invalid slot" do
      %{
        mobo: mobo,
        cpu: cpu,
        hdd: hdd
      } = ComponentSetup.mobo_components()

      i0 = [{hdd, :cpu_0}, {cpu, :hdd_0}]
      i1 = [{cpu, :cpu_0}, {hdd, :hdd_9}]

      assert {:error, reason} = MotherboardInternal.setup(mobo, i0)
      assert reason == :wrong_slot_type

      assert {:error, reason} = MotherboardInternal.setup(mobo, i1)
      assert reason == :bad_slot
    end

    test "requires that all basic components are present" do
      %{mobo: mobo, cpu: cpu} = ComponentSetup.mobo_components()

      # Missing hdd, ram, nic...
      initial_components = [{cpu, :cpu_0}]

      assert {:error, reason} =
        MotherboardInternal.setup(mobo, initial_components)
      assert reason == :missing_initial_components
    end

    test "cant link a mobo onto another mobo (that would be cool though)" do
      %{
        mobo: mobo,
        cpu: _cpu,
        hdd: hdd
      } = ComponentSetup.mobo_components()

      initial_components =
        [
          {mobo, :cpu_0},
          {hdd, :hdd_0}
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
        MotherboardInternal.link(motherboard, mobo, cpu, :cpu_1)

      assert entry.motherboard_id == mobo.component_id
      assert entry.linked_component_id == cpu.component_id
      assert entry.slot_id == :cpu_1

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
        MotherboardInternal.link(motherboard, mobo, cpu, :cpu_0)
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

      MotherboardInternal.unlink(motherboard, hdd)

      new_motherboard = MotherboardInternal.fetch(mobo.component_id)

      refute motherboard == new_motherboard
      refute Map.has_key?(new_motherboard.slots, :hdd_0)

      # The new motherboard has one less component attached to it
      assert length(new_motherboard.slots |> Map.to_list()) ==
        length(motherboard.slots |> Map.to_list()) - 1
    end

    test "performs a noop if the component is not linked" do
      {_, %{mobo: mobo}} = ComponentSetup.motherboard()
      {component, _} = ComponentSetup.component()

      motherboard = MotherboardInternal.fetch(mobo.component_id)

      MotherboardInternal.unlink(motherboard, component)

      new_motherboard = MotherboardInternal.fetch(mobo.component_id)

      assert motherboard == new_motherboard
    end
  end
end
