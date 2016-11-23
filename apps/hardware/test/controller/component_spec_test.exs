defmodule HELM.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentType, as: MdlCompType
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec

  @component_type HRand.string(min: 20)

  setup_all do
    %{component_type: @component_type}
    |> MdlCompType.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    payload = %{component_type: @component_type, spec: %{}}
    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlCompSpec.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, comp_spec} = CtrlCompSpec.create(payload)
      assert {:ok, ^comp_spec} = CtrlCompSpec.find(comp_spec.spec_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlCompSpec.find(IPv6.generate([]))
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    {:ok, comp_spec} = CtrlCompSpec.create(payload)
    assert :ok = CtrlCompSpec.delete(comp_spec.spec_id)
    assert :ok = CtrlCompSpec.delete(comp_spec.spec_id)
  end
end