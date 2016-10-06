defmodule HELM.Hardware.Component.Spec.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware
  alias HELM.Hardware.Component

  def new(component_type, spec) do
    %{component_type: component_type, spec: spec}
    |> Component.Spec.Schema.create_changeset
    |> do_new_spec
  end

  def do_new_spec(changeset) do
    case Hardware.Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:spec:created", changeset.changes.spec_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
