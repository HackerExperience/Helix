defmodule HELM.Hardware.Controller.ComponentSpec do

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec
  import Ecto.Query, only: [where: 3]

  @spec create(%{component_type: String.t, spec: %{}}) :: {:ok, MdlCompSpec.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlCompSpec.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, MdlCompSpec.t} | {:error, :notfound}
  def find(spec_id) do
    case Repo.get_by(MdlCompSpec, spec_id: spec_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(spec_id) do
    MdlCompSpec
    |> where([s], s.spec_id == ^spec_id)
    |> Repo.delete_all()

    :ok
  end
end