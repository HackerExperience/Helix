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

  @spec update(String.t, ComponentSpec.update_params) :: {:ok, ComponentSpec.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(spec_id, params) do
    with {:ok, comp_spec} <- find(spec_id) do
      comp_spec
      |> ComponentSpec.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec delete(String.t) :: no_return
  def delete(spec_id) do
    spec_id
    |> ComponentSpec.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end