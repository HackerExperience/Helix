defmodule Helix.Hardware.Internal.Component do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Repo

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

  @spec fetch(Component.id) ::
    Component.t
    | nil
  def fetch(component_id),
    do: Repo.get(Component, component_id) |> Repo.preload(:slot)

  @spec delete(Component.t | Component.id) ::
    :ok
  def delete(component = %Component{}),
    do: delete(component.component_id)
  def delete(component_id) do
    component_id
    |> Component.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  def get_motherboard(component = %Component{component_type: :mobo}) do
    component.component_id
  end

  def get_motherboard(component = %Component{}) do
    component
    |> Repo.preload(:slot)
    |> Map.get(:slot)
    |> case do
         nil ->
           nil
         slot ->
           Map.get(slot, :motherboard_id)
       end
  end

  def get_motherboard(component_id) do
    component_id
    |> fetch()
    |> get_motherboard()
  end
end
