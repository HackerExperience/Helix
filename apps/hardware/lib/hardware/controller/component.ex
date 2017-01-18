defmodule Helix.Hardware.Controller.Component do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Repo

  @spec create(Component.creation_params) :: {:ok, Component.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Component.create_changeset()
    |> Repo.insert()
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