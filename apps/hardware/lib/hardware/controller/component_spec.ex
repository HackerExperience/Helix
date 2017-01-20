defmodule Helix.Hardware.Controller.ComponentSpec do

  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  @spec create(ComponentSpec.creation_params) :: {:ok, ComponentSpec.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> ComponentSpec.create_changeset()
    |> Repo.insert()
  end

  @spec find(String.t) :: {:ok, ComponentSpec.t} | {:error, :notfound}
  def find(spec_id) do
    case Repo.get_by(ComponentSpec, spec_id: spec_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec update(ComponentSpec.t, ComponentSpec.update_params) :: {:ok, ComponentSpec.t} | {:error, Ecto.Changeset.t}
  def update(component_spec, params) do
    component_spec
    |> ComponentSpec.update_changeset(params)
    |> Repo.update()
  end

  @spec delete(ComponentSpec.t | String.t) :: no_return
  def delete(%ComponentSpec{spec_id: sid}),
    do: delete(sid)
  def delete(spec_id) do
    spec_id
    |> ComponentSpec.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end