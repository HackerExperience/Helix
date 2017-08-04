defmodule Helix.Hardware.Internal.Component do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec fetch(Component.id) ::
    Component.t
    | nil
  def fetch(id),
    do: Repo.get(Component, id)

  @spec get_motherboard_slot(Component.t | Component.id) ::
    MotherboardSlot.t
    | nil
  def get_motherboard_slot(component) do
    component
    |> MotherboardSlot.Query.by_component()
    # |> MotherboardSlot.Query.only_linked_slots()
    |> Repo.one()
  end

  @spec get_motherboard_id(Component.t | Component.id) ::
    Motherboard.id
    | nil
  def get_motherboard_id(nil),
    do: nil
  def get_motherboard_id(component = %Component{component_type: :mobo}),
    do: component.component_id
  def get_motherboard_id(component = %Component{}) do
    case Repo.preload(component, :slot) do
      %{slot: nil} ->
        nil
      %{slot: %{motherboard_id: id}} ->
        id
    end
  end
  def get_motherboard_id(component_id) do
    component_id
    |> fetch()
    |> get_motherboard_id()
  end

  @spec create_from_spec(ComponentSpec.t) ::
    {:ok, Component.t}
    | {:error, Ecto.Changeset.t}
  def create_from_spec(spec = %ComponentSpec{}) do
    module = ComponentType.type_implementation(spec.component_type)

    changeset = module.create_from_spec(spec)

    case Repo.insert(changeset) do
      {:ok, %{component: c}} ->
        {:ok, c}
      e ->
        e
    end
  end

  @spec delete(Component.t) ::
    :ok
  def delete(component) do
    motherboard_id = get_motherboard_id(component)

    Repo.delete(component)

    CacheAction.purge_component(component)
    unless is_nil(motherboard_id) do
      CacheAction.update_server_by_motherboard(motherboard_id)
    end

    :ok
  end
end
