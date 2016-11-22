defmodule HELM.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentSpec
  alias HELM.Hardware.Model.ComponentType
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec

  setup_all do
    # FIXME
    type = case Repo.all(ComponentType) do
      [] ->
        %{component_type: Burette.Color.name()}
        |> ComponentType.create_changeset()
        |> Repo.insert!()
      ct = [_|_] ->
        Enum.random(ct)
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
      assert {:error, :notfound} === CtrlCompSpec.find(Random.pk())
    end
  end

  test "delete is idempotent", %{component_spec: cs} do
    assert Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
    CtrlCompSpec.delete(cs.spec_id)
    CtrlCompSpec.delete(cs.spec_id)
    CtrlCompSpec.delete(cs.spec_id)
    refute Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
  end

  describe "update/2" do
    test "update spec information", %{payload: payload} do
      assert {:ok, spec} = CtrlCompSpec.create(payload)

      spec_data = %{test: HRand.string()}
      payload2 = %{spec: spec_data}

      assert {:ok, spec} = CtrlCompSpec.update(spec.spec_id, payload2)
      assert spec.spec == spec_data
    end

    test "spec not found" do
      assert {:error, :notfound} = CtrlCompSpec.update(IPv6.generate([]), %{})
    end
  end
end