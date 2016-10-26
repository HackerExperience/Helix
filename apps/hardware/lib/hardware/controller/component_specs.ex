defmodule HELM.Hardware.Controller.ComponentSpecs do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Model.Repo
  alias HELM.Hardware.Model.ComponentSpecs, as: MdlCompSpecs

  def create(payload) do
    MdlCompSpecs.create_changeset(payload)
    |> do_create()
  end

  def find(spec_id) do
    case Repo.get_by(MdlCompSpecs, spec_id: spec_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(spec_id) do
    MdlCompSpecs
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