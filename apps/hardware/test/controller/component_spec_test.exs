defmodule HELM.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentSpec
  alias HELM.Hardware.Model.ComponentType
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec

  setup_all do
    type = case Repo.all(ComponentType) do
      [] ->
        %{component_type: Burette.Color.name()}
        |> ComponentType.create_changeset()
        |> Repo.insert!()
      [component_type| _] ->
        component_type
    end

    [component_type: type]
  end

  setup context do
    component_spec =
      %{
        component_type: context.component_type.component_type,
        spec: %{}}
      |> ComponentSpec.create_changeset()
      |> Repo.insert!()

    {:ok, component_spec: component_spec}
  end

  describe "find" do
    test "fetching component_spec by id", %{component_spec: cs} do
      assert {:ok, _} = CtrlCompSpec.find(cs.spec_id)
    end

    test "returns error when spec doesn't exists" do
      assert {:error, :notfound} === CtrlCompSpec.find(HELL.TestHelper.Random.pk())
    end
  end

  test "delete is idempotent", %{component_spec: cs} do
    assert Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
    assert CtrlCompSpec.delete(cs.spec_id)
    assert CtrlCompSpec.delete(cs.spec_id)
    assert CtrlCompSpec.delete(cs.spec_id)
    refute Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
  end
end