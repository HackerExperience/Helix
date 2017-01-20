defmodule Helix.Hardware.Controller.Component do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Repo

  @spec create_from_spec(ComponentSpec.t) :: {:ok, Component.t} | {:error, Ecto.Changeset.t}
  def create_from_spec(component_spec) do
    module = case component_spec.component_type do
      "mobo" ->
        Motherboard
      "hdd" ->
        Component.HDD
      "cpu" ->
        Component.CPU
      "ram" ->
        Component.RAM
      "nic" ->
        Component.NIC
    end

    component_spec
    |> module.create_from_spec()
    |> Repo.insert()
    |> case do
      {:ok, %{component: c}} ->
        {:ok, c}
      e ->
        e
    end
  end

  @spec find(HELL.PK.t) :: {:ok, Component.t} | {:error, :notfound}
  def find(component_id) do
    case Repo.get_by(Component, component_id: component_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(component_id) do
    component_id
    |> Component.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end