defmodule Helix.Hardware.Controller.ComponentSpec do

  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  @spec create(ComponentSpec.spec) :: {:ok, ComponentSpec.t} | {:error, Ecto.Changeset.t}
  def create(spec_params) do
    spec_params
    |> ComponentSpec.create_from_spec()
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
