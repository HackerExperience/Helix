defmodule HELM.Hardware.Controller.ComponentSpec do

  import Ecto.Query, only: [where: 3]

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec

  def create(payload) do
    MdlCompSpec.create_changeset(payload)
    |> Repo.insert()
  end

  def find(spec_id) do
    case Repo.get_by(MdlCompSpec, spec_id: spec_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(spec_id) do
    MdlCompSpec
    |> where([s], s.spec_id == ^spec_id)
    |> Repo.delete_all()

    :ok
  end
end