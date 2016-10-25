defmodule HELM.Hardware.Controller.ComponentSpecs do
  import Ecto.Query

  alias HELF.{Broker, Error}
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
    with {:ok, comp_spec} <- find(spec_id),
         {:ok, _} <- Repo.delete(comp_spec) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end

  def do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:spec:created", changeset.changes.spec_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp do_delete(component_spec) do
    case Repo.delete(component_spec) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end