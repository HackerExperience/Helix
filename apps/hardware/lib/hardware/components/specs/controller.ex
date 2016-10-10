defmodule HELM.Hardware.Component.Spec.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Component.Spec.Schema, as: CompSpecSchema

  def create(component_type, spec) do
    %{component_type: component_type, spec: spec}
    |> CompSpecSchema.create_changeset
    |> do_create
  end

  def find(spec_id) do
    case Repo.get_by(CompSpecSchema, spec_id: spec_id) do
      nil -> {:error, "Component.Spec not found."}
      res -> {:ok, res}
    end
  end

  def delete(spec_id) do
    case find(spec_id) do
      {:ok, spec} -> do_delete(spec)
      error -> error
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
