defmodule Helix.Test.Server.Component.Setup do

  alias Ecto.Changeset
  alias Helix.Server.Internal.Component, as: ComponentInternal
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Model.Component
  alias Helix.Server.Repo, as: ServerRepo

  alias Helix.Test.Network.Helper, as: NetworkHelper
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
        comp_opts = opts[:type] && [type: opts[:type]] || []
        ComponentHelper.random_spec(comp_opts)
      end

    custom = Keyword.get(opts, :custom, %{})

    custom =
      if spec.component_type == :nic and Enum.empty?(custom) do
        %{ulk: 100, dlk: 100, network_id: "::"}
      else
        custom
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
  - nic_opts: Relay to `nic/1`
  """
  def mobo_components(opts \\ []) do
    mobo_spec_id = Keyword.get(opts, :mobo_spec_id, :mobo_001)

    {mobo, _} = component(type: :mobo, spec_id: mobo_spec_id)
    {cpu, _} = component(type: :cpu)
    # {ram, _} = component(type: :ram)
    {hdd, _} = component(type: :hdd)
    {nic, _} = nic(opts[:nic_opts] || [])

    %{
      mobo: mobo,
      cpu: cpu,
      hdd: hdd,
      nic: nic
    }
  end

  @doc """
  Opts:
  - spec_id: set mobo spec id
  - nic_opts: Relay to `nic/1`
  """
  def motherboard(opts \\ []) do
    mobo_opts = opts[:spec_id] && [mobo_spec_id: opts[:spec_id]] || []
    nic_opts = opts[:nic_opts] || []

    components_opts = mobo_opts ++ [nic_opts: nic_opts]

    %{
      mobo: mobo,
      cpu: cpu,
      hdd: hdd,
      nic: nic
    } = related = mobo_components(components_opts)

    initial_components =
      [
        {cpu, :cpu_0},
        {hdd, :hdd_0},
        {nic, :nic_0}
      ]

    {:ok, entries} = MotherboardInternal.setup(mobo, initial_components)

    {entries, related}
  end

  @doc """
  Opts:
  - network_id: Set network id. Defaults to internet
  - dlk: Set dlk. Defaults to 0 (!)
  - ulk: Set ulk. Defaults to 0 (!)
  """
  def nic(opts \\ []) do
    {nic, _} = component(type: :nic)

    network_id = Keyword.get(opts, :network_id, NetworkHelper.internet_id())
    dlk = Keyword.get(opts, :dlk, 0)
    ulk = Keyword.get(opts, :ulk, 0)

    custom = %{dlk: dlk, ulk: ulk, network_id: network_id}

    {:ok, nic} = ComponentInternal.update_custom(nic, custom)

    {nic, %{}}
  end
end
