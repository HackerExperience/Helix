defmodule Helix.Hardware.Service.API.Bundle do

  # REVIEW: this module's usefulness, I've just done what made sense
  # it's kinda overenginerring too

  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Service.API.Component, as: ComponentAPI
  alias Helix.Hardware.Service.API.ComponentSpec, as: ComponentSpecAPI
  alias Helix.Hardware.Service.API.Motherboard, as: MotherboardAPI

  # REVIEW: these functions are using `Repo.transaction/1`, is it okay?
  alias Helix.Hardware.Repo

  @initial_bundle %{
    motherboard: "MOBO01",
    components: [
      {:cpu, "CPU01"},
      {:ram, "RAM01"},
      {:hdd, "HDD01"},
      {:nic, "NIC01"}
    ],
    network: [
      {"::", uplink: 100, downlink: 100}
    ]
  }

  @spec create(map) ::
    {:ok, %{motherboard: PK.t, components: [PK.t]}}
    | {:error, reason :: term}
  def create(bundle \\ @initial_bundle) do
    Repo.transaction(fn ->
      with \
        {:ok, [motherboard | components]} <- create_bundle_components(bundle),
        {:ok, _} <- link_components(motherboard, components)
      do
        %{
          motherboard: motherboard.component_id,
          components: Enum.map(components, &(&1.component_id))
        }
      else
        _ ->
          Repo.rollback(:internal)
      end
    end)
  end

  @spec create_bundle_components(map) ::
    {:ok, [Component.t]}
    | {:error, reason :: term}
  defp create_bundle_components(bundle) do
    # motherboard is the first index as long as we keep using an even number
    # of reduce functions
    spec_ids = [bundle.motherboard | Keyword.values(bundle.components)]

    with {:ok, specs} <- fetch_specs(spec_ids) do
      create_components(specs)
    end
  end

  @spec fetch_specs([PK.t]) ::
    {:ok, [ComponentSpec.t]}
    | {:error, reason :: term}
  defp fetch_specs(spec_ids) do
    result =
      Enum.reduce_while(spec_ids, [], fn spec_id, specs ->
        case ComponentSpecAPI.fetch(spec_id) do
          nil ->
            {:halt, :error}
          spec ->
            {:cont, [spec | specs]}
        end
      end)

    case result do
      :error ->
        {:error, :internal}
      specs ->
        {:ok, specs}
    end
  end

  @spec create_components([ComponentSpec.t]) ::
    {:ok, [Component.t]}
    | {:error, reason :: term}
  defp create_components(specs) do
    result =
      Enum.reduce_while(specs, [], fn spec, components ->
        case ComponentAPI.create_from_spec(spec) do
          {:ok, component} ->
            {:cont, [component | components]}
          {:error, _} ->
            {:halt, :error}
        end
      end)

    case result do
      :error ->
        {:error, :internal}
      components ->
        {:ok, components}
    end
  end

  @spec link_components(motherboard :: Component.t, [Component.t]) ::
    {:ok, [Component.t]}
    | {:error, reason :: term}
  defp link_components(motherboard, components) do
    motherboard
    |> group_component_slots(components)
    |> link_grouped_components()
  end

  @spec group_component_slots(motherboard :: Component.t, [Component.t]) ::
    [{MotherboardSlot.t, Component.t}]
  defp group_component_slots(motherboard, components) do
    components = Enum.group_by(components, &(&1.component_type))

    slots =
      motherboard.component_id
      |> MotherboardAPI.get_slots()
      |> Enum.group_by(&(&1.link_component_type))

    slot_types = Map.keys(slots)

    # REVIEW: map.merge is also an option, but I think it's ugly to use
    slot_component_nested_list =
      Enum.reduce(slot_types, [], fn type, accum ->
        zip_slots_components = Enum.zip(slots[type], components[type])
        [zip_slots_components | accum]
      end)

    List.flatten(slot_component_nested_list)
  end

  @spec link_grouped_components([{MotherboardSlot.t, Component.t}]) ::
    {:ok, [Component.t]}
    | {:error, reason :: term}
  defp link_grouped_components(group) do
    result =
      Enum.reduce_while(group, [], fn {slot, component}, acc ->
        case MotherboardAPI.link(slot, component) do
          {:ok, _} ->
            {:cont, [component | acc]}
          {:error, _} ->
            {:halt, :error}
          end
      end)

    case result do
      :error ->
        {:error, :internal}
      components ->
        {:ok, components}
    end
  end
end
