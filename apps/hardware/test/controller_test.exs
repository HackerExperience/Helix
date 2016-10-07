defmodule HELM.Hardware.ControllerTest do
  use ExUnit.Case

  alias HELM.Hardware.{Component, Motherboard}

  def random_num do
    :rand.uniform(8001)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end

  describe "Component.Type.Controller" do
    test "new_type/1 success" do
      assert {:ok, _} = Component.Type.Controller.new_type(random_str)
    end

    test "find_type/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      assert {:ok, comp_type} = Component.Type.Controller.find_type(comp_type.component_type)
    end

    test "remove_type/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      assert {:ok, _} = Component.Type.Controller.remove_type(comp_type.component_type)
    end
  end

  describe "Component.Spec.Controller" do
    test "new_spec/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      assert {:ok, _} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
    end

    test "find_spec/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      assert {:ok, comp_spec} = Component.Spec.Controller.find_spec(comp_spec.spec_id)
    end

    test "remove_spec/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      assert {:ok, _} = Component.Spec.Controller.remove_spec(comp_spec.spec_id)
    end
  end

  describe "Component.Controller" do
    test "new_component/2 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      assert {:ok, _} = Component.Controller.new_component(comp_type.component_type, comp_spec.spec_id)
    end

    test "find_component/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      {:ok, comp} = Component.Controller.new_component(comp_type.component_type,
                                                       comp_spec.spec_id)
      assert {:ok, comp} = Component.Controller.find_component(comp.component_id)
    end

    test "remove_component/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      {:ok, comp} = Component.Controller.new_component(comp_type.component_type,
                                                       comp_spec.spec_id)
      assert {:ok, _} = Component.Controller.remove_component(comp.component_id)
    end
  end

  describe "Motherboard.Controller" do
    test "new_motherboard/0 success" do
      {:ok, _} = Motherboard.Controller.new_motherboard
    end

    test "find_component/1 success" do
      {:ok, mobo} = Motherboard.Controller.new_motherboard
      assert {:ok, mobo} = Motherboard.Controller.find_motherboard(mobo.motherboard_id)
    end

    test "remove_component/1 success" do
      {:ok, mobo} = Motherboard.Controller.new_motherboard
      assert {:ok, _} = Motherboard.Controller.delete_motherboard(mobo.motherboard_id)
    end
  end

  describe "Motherboard.Slot.Controller" do
    test "new_slot/0 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      {:ok, comp} = Component.Controller.new_component(comp_type.component_type,
                                                       comp_spec.spec_id)
      {:ok, mobo} = Motherboard.Controller.new_motherboard
      assert {:ok, _} = Motherboard.Slot.Controller.new_slot(mobo.motherboard_id,
                                                             random_num,
                                                             comp_type.component_type,
                                                             comp.component_id)
    end

    test "find_component/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      {:ok, comp} = Component.Controller.new_component(comp_type.component_type,
                                                       comp_spec.spec_id)
      {:ok, mobo} = Motherboard.Controller.new_motherboard
      {:ok, slot} = Motherboard.Slot.Controller.new_slot(mobo.motherboard_id,
                                                         random_num,
                                                         comp_type.component_type,
                                                         comp.component_id)
      assert {:ok, slot} = Motherboard.Slot.Controller.find_slot(slot.slot_id)
    end

    test "remove_component/1 success" do
      {:ok, comp_type} = Component.Type.Controller.new_type(random_str)
      {:ok, comp_spec} = Component.Spec.Controller.new_spec(comp_type.component_type, %{})
      {:ok, comp} = Component.Controller.new_component(comp_type.component_type,
                                                       comp_spec.spec_id)
      {:ok, mobo} = Motherboard.Controller.new_motherboard
      {:ok, slot} = Motherboard.Slot.Controller.new_slot(mobo.motherboard_id,
                                                         random_num,
                                                         comp_type.component_type,
                                                         comp.component_id)
      assert {:ok, _} = Motherboard.Slot.Controller.delete_slot(slot.slot_id)
    end
  end
end
