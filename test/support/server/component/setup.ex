defmodule Helix.Test.Server.Component.Setup do

  alias Ecto.Changeset
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Model.Component
  alias Helix.Server.Repo, as: ServerRepo

  alias Helix.Test.Server.Component.Helper, as: ComponentHelper

  @doc """
  See doc on `fake_component/1`
  """
  def component(opts \\ []) do
    {_, related = %{changeset: changeset}} = fake_component(opts)
    {:ok, inserted} = ServerRepo.insert(changeset)
    {inserted, related}
  end

  @doc """
  - spec_id: Set spec id. Defaults to randomly generated one
  - type: component type. Ignored if `spec_id` is passed

  Related: Component.Spec.t, Component.changeset
  """
  def fake_component(opts \\ []) do

    spec =
      if opts[:spec_id] do
        Component.Spec.fetch(opts[:spec_id])
      else
        opts = opts[:type] && [type: opts[:type]] || []
        ComponentHelper.random_spec(opts)
      end

    changeset = Component.create_from_spec(spec)

    component = Changeset.apply_changes(changeset)

    related =
      %{
        spec: spec,
        changeset: changeset
      }

    {component, related}
  end

  @doc """
  No opts for you
  """
  def mobo_components(opts \\ []) do
    mobo_spec_id = Keyword.get(opts, :mobo_spec_id, :mobo_001)

    {mobo, _} = component(type: :mobo, spec_id: mobo_spec_id)
    {cpu, _} = component(type: :cpu)
    # {ram, _} = component(type: :ram)
    {hdd, _} = component(type: :hdd)

    %{
      mobo: mobo,
      cpu: cpu,
      hdd: hdd
    }
  end

  @doc """
  Opts:
  spec_id: set mobo spec id
  """
  def motherboard(opts \\ []) do
    mobo_opts = opts[:spec_id] && [mobo_spec_id: opts[:spec_id]] || []

    %{
      mobo: mobo,
      cpu: cpu,
      hdd: hdd
    } = related = mobo_components(mobo_opts)

    initial_components =
      [
        {cpu, :cpu_0},
        {hdd, :hdd_0}
      ]

    {:ok, entries} = MotherboardInternal.setup(mobo, initial_components)

    {entries, related}
  end
end
