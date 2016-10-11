defmodule HELM.Hardware.ControllerTest do
  use ExUnit.Case

  alias HELM.Hardware.Motherboard.Controller, as: MoboCtrl
  alias HELM.Hardware.Motherboard.Slot.Controller, as: MoboSlotCtrl
  alias HELM.Hardware.Component.Controller, as: CompCtrl
  alias HELM.Hardware.Component.Type.Controller, as: CompTypeCtrl
  alias HELM.Hardware.Component.Spec.Controller, as: CompSpecCtrl

  def random_num do
    :rand.uniform(134217727)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end

  describe "HELM.Hardware.Component.Type.Controller" do
    test "create/1 success" do
      assert {:ok, _} = CompTypeCtrl.create(random_str)
    end

    test "find/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      assert {:ok, comp_type} = CompTypeCtrl.find(comp_type.component_type)
    end

    test "all/0 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      types = CompTypeCtrl.all()
      assert Enum.member?(types, comp_type.component_type)
    end

    test "delete/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      assert {:ok, _} = CompTypeCtrl.delete(comp_type.component_type)
    end
  end

  describe "HELM.Hardware.Component.Spec.Controller" do
    test "create/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      assert {:ok, _} = CompSpecCtrl.create(comp_type.component_type, %{})
    end

    test "find/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      assert {:ok, comp_spec} = CompSpecCtrl.find(comp_spec.spec_id)
    end

    test "delete/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      assert {:ok, _} = CompSpecCtrl.delete(comp_spec.spec_id)
    end
  end

  describe "HELM.Hardware.Component.Controller" do
    test "create/2 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      assert {:ok, _} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
    end

    test "find/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      {:ok, comp} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
      assert {:ok, comp} = CompCtrl.find(comp.component_id)
    end

    test "delete/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      {:ok, comp} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
      assert {:ok, _} = CompCtrl.delete(comp.component_id)
    end
  end

  describe "HELM.Hardware.Motherboard.Controller" do
    test "create/0 success" do
      {:ok, _} = MoboCtrl.create
    end

    test "find/1 success" do
      {:ok, mobo} = MoboCtrl.create
      assert {:ok, mobo} = MoboCtrl.find(mobo.motherboard_id)
    end

    test "delete/1 success" do
      {:ok, mobo} = MoboCtrl.create
      assert {:ok, _} = MoboCtrl.delete(mobo.motherboard_id)
    end
  end

  describe "HELM.Hardware.Motherboard.Slot.Controller" do

    test "create/0 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      {:ok, comp} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
      {:ok, mobo} = MoboCtrl.create
      assert {:ok, _} = MoboSlotCtrl.create(mobo.motherboard_id,
                                            random_num,
                                            comp_type.component_type,
                                            comp.component_id)
    end

    test "find/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      {:ok, comp} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
      {:ok, mobo} = MoboCtrl.create
      {:ok, slot} = MoboSlotCtrl.create(mobo.motherboard_id,
                                        random_num,
                                        comp_type.component_type,
                                        comp.component_id)
      assert {:ok, slot} = MoboSlotCtrl.find(slot.slot_id)
    end

    test "delete/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      {:ok, comp} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
      {:ok, mobo} = MoboCtrl.create
      {:ok, slot} = MoboSlotCtrl.create(mobo.motherboard_id,
                                        random_num,
                                        comp_type.component_type,
                                        comp.component_id)
      assert {:ok, _} = MoboSlotCtrl.delete(slot.slot_id)
    end

    test "link/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      {:ok, comp} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
      {:ok, mobo} = MoboCtrl.create
      {:ok, slot} = MoboSlotCtrl.create(%{motherboard_id: mobo.motherboard_id,
                                          internal_id: random_num,
                                          component_type: comp_type.component_type})
      assert {:ok, _} = MoboSlotCtrl.link(slot.slot_id, comp.component_id)
    end

    test "unlink/1 success" do
      {:ok, comp_type} = CompTypeCtrl.create(random_str)
      {:ok, comp_spec} = CompSpecCtrl.create(comp_type.component_type, %{})
      {:ok, comp} = CompCtrl.create(comp_type.component_type, comp_spec.spec_id)
      {:ok, mobo} = MoboCtrl.create
      {:ok, slot} = MoboSlotCtrl.create(%{motherboard_id: mobo.motherboard_id,
                                          internal_id: random_num,
                                          component_type: comp_type.component_type})
      {:ok, _} = MoboSlotCtrl.link(slot.slot_id, comp.component_id)
      assert {:ok, _} = MoboSlotCtrl.unlink(slot.slot_id)
    end
  end
end
