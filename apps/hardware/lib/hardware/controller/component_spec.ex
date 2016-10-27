defmodule HELM.Hardware.Controller.ComponentSpec do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec

  def create(payload) do
    MdlCompSpec.create_changeset(payload)
    |> do_create()
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

  def do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:spec:created", schema.spec_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end